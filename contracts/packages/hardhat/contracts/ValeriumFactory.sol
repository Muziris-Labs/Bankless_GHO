//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import "./ValeriumStorage.sol";
import "./Valerium.sol";

contract ValeriumFactory is ValeriumStorage, ERC2771Context, OwnerIsCreator, CCIPReceiver{

    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw(); 
    error FailedToWithdrawEth(address owner, address target, uint256 value); 
    error DestinationChainNotAllowlisted(uint64 destinationChainSelector); 
    error SourceChainNotAllowlisted(uint64 sourceChainSelector); 
    error SenderNotAllowlisted(address sender); 

    event ValeriumCreated(string name, address valerium);

    Valerium public immutable accountImplementation;

    IERC20 private s_linkToken;

    address public passkeyVerifier;

    address public recoveryVerifier;

    mapping(uint64 => bool) public allowlistedDestinationChains;

    mapping(uint64 => bool) public allowlistedSourceChains;

    mapping(address => bool) public allowlistedSenders;

    constructor(address _router, 
        address _link, 
        address _trustedForwarder, 
        address _gasTank, 
        address _passkeyVerifier,
        address _recoveryVerifier,
        address _ghoToken, 
        address _ghoAggregator, 
        address _ethAggregator) ERC2771Context(_trustedForwarder) CCIPReceiver(_router) {
        accountImplementation = new Valerium(_trustedForwarder, _gasTank, _ghoToken, _ghoAggregator, _ethAggregator);
        s_linkToken = IERC20(_link);
        passkeyVerifier = _passkeyVerifier;
        recoveryVerifier = _recoveryVerifier;
    }

     modifier onlyTrustedForwarder() {
        require(isTrustedForwarder(msg.sender), "caller is not the trusted forwarder");
        _;
    }

    modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
        if (!allowlistedDestinationChains[_destinationChainSelector])
            revert DestinationChainNotAllowlisted(_destinationChainSelector);
        _;
    }

    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector])
            revert SourceChainNotAllowlisted(_sourceChainSelector);
        if (!allowlistedSenders[_sender]) revert SenderNotAllowlisted(_sender);
        _;
    }

    function allowlistDestinationChain(
        uint64 _destinationChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedDestinationChains[_destinationChainSelector] = allowed;
    }

    function allowlistSourceChain(
        uint64 _sourceChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
    }

    function allowlistSender(address _sender, bool allowed) external onlyOwner {
        allowlistedSenders[_sender] = allowed;
    }

    function sendMessagePayLINK(
        uint64 _destinationChainSelector,
        address _receiver,
        string memory name, 
        bytes memory _passkeyInputs, 
        bytes32 _recoveryKeyHash, 
        uint256 salt
    )
        internal
        onlyAllowlistedDestinationChain(_destinationChainSelector)
        returns (bytes32 messageId)
    {
       
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            name,
            _passkeyInputs,
            _recoveryKeyHash,
            salt,
            address(s_linkToken)
        );

        IRouterClient router = IRouterClient(this.getRouter());

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > s_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);

        s_linkToken.approve(address(router), fees);

        messageId = router.ccipSend(_destinationChainSelector, evm2AnyMessage);

        return messageId;
    }

    function _buildCCIPMessage(
        address _receiver,
        string memory name, 
        bytes memory _passkeyInputs, 
        bytes32 _recoveryKeyHash, 
        uint256 salt,
        address _feeTokenAddress
    ) internal pure returns (Client.EVM2AnyMessage memory) {
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver),
                data: abi.encode(name, _passkeyInputs, _recoveryKeyHash, salt),
                tokenAmounts: new Client.EVMTokenAmount[](0),
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: 900_000})
                ),
                feeToken: _feeTokenAddress
            });
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    )
        internal
        override
        onlyAllowlisted(
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address))
        ) 
    {
        (
            string memory name, 
            bytes memory _passkeyInputs, 
            bytes32 _recoveryKeyHash, 
            uint256 salt
        ) = abi.decode(any2EvmMessage.data, (string,  bytes,  bytes32, uint256));

        require(ValeriumNameToDetails[name].walletAddress == address(0), "Valerium already exists");

        Valerium valerium = createAccount(name, _passkeyInputs, _recoveryKeyHash, salt);

        emit ValeriumCreated(name, address(valerium));
    }

    function createAccount(
        string memory name, 
        bytes memory _passkeyInputs, 
        bytes32 _recoveryKeyHash, 
        uint256 salt) public returns (Valerium ret) {
        address addr = getAddress(passkeyVerifier, _passkeyInputs, recoveryVerifier, _recoveryKeyHash, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return Valerium(payable(addr));
        }
        ret = Valerium(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(Valerium.initialize, (passkeyVerifier, _passkeyInputs, recoveryVerifier, _recoveryKeyHash))
            )));
        addValerium(name, address(ret));
    }

    function createExternalAccount(
        uint64 _destinationChainSelector, 
        address _receiver,
        string memory name, 
        uint256 salt) public returns (Valerium ret) {
        require(ValeriumNameToDetails[name].walletAddress != address(0), "Valerium does not exist");
        
        Valerium valerium = Valerium(payable(ValeriumNameToDetails[name].walletAddress));
        bytes memory _passkeyInputs = valerium.inputs();
        bytes32 _recoveryKeyHash = valerium.recoveryKeyHash();

        sendMessagePayLINK(_destinationChainSelector, _receiver, name,  _passkeyInputs, _recoveryKeyHash, salt);

        emit ValeriumCreated(name, address(ret));
    }

    function getAddress( address _passkeyVerifier, 
    bytes memory _passkeyInputs, 
    address _recoveryVerifier, 
    bytes32 _recoveryKeyHash,
    uint256 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(
                address(accountImplementation),
                abi.encodeCall(Valerium.initialize, (_passkeyVerifier, _passkeyInputs, _recoveryVerifier, _recoveryKeyHash))
            )
        )));
    }
}