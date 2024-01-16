//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import "./ValeriumStorage.sol";
import "./Valerium.sol";

contract ValeriumFactory is ValeriumStorage, ERC2771Context {
    Valerium public immutable accountImplementation;

    constructor(address _trustedForwarder, address _gasTank, address _ghoToken, address _ghoAggregator, address _ethAggregator) ERC2771Context(_trustedForwarder) {
        accountImplementation = new Valerium(_trustedForwarder, _gasTank, _ghoToken, _ghoAggregator, _ethAggregator);
    }

     modifier onlyTrustedForwarder() {
        require(isTrustedForwarder(msg.sender), "caller is not the trusted forwarder");
        _;
    }

    function createAccount(string memory name, address _passkeyVerifier, bytes memory _passkeyInputs, address _recoveryVerifier, bytes32 _recoveryKeyHash, uint256 salt) onlyTrustedForwarder public returns (Valerium ret) {
        address addr = getAddress(_passkeyVerifier, _passkeyInputs, _recoveryVerifier, _recoveryKeyHash, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return Valerium(payable(addr));
        }
        ret = Valerium(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(Valerium.initialize, (_passkeyVerifier, _passkeyInputs, _recoveryVerifier, _recoveryKeyHash))
            )));
        addValerium(name, address(ret));
    }

    function getAddress( address _passkeyVerifier, bytes memory _passkeyInputs, address _recoveryVerifier, bytes32 _recoveryKeyHash,uint256 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(
                address(accountImplementation),
                abi.encodeCall(Valerium.initialize, (_passkeyVerifier, _passkeyInputs, _recoveryVerifier, _recoveryKeyHash))
            )
        )));
    }
}