//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./callback/TokenCallbackHandler.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./base/PasskeyManager.sol";
import "./base/RecoveryManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Valerium is TokenCallbackHandler, Initializable, PasskeyManager, RecoveryManager {
    address public VALERIUM_FORWARDER;
    address public VALERIUM_GAS_TANK;
    address public GHO_TOKEN;

    constructor(address _forwarder, address _gasTank, address _ghoToken) {
        VALERIUM_FORWARDER = _forwarder;
        VALERIUM_GAS_TANK = _gasTank;
        GHO_TOKEN = _ghoToken;
    }

    modifier onlyValeriumForwarder() {
        require(msg.sender == VALERIUM_FORWARDER, "Only Valerium can call this function");
        _;
    }

    function initialize(address _passkeyVerifier, bytes memory _passkeyInputs, address _recoveryVerifier, bytes32 _recoveryKeyHash) public virtual initializer {
        _initialize(_passkeyVerifier, _passkeyInputs, _recoveryVerifier, _recoveryKeyHash);
    }


    function _initialize(address _passkeyVerifier, bytes memory _passkeyInputs, address _recoveryVerifier, bytes32 _recoveryKeyHash) internal virtual {
        _initializePasskeyManager(_passkeyVerifier, _passkeyInputs);
        _initializeRecoveryManager(_recoveryVerifier, _recoveryKeyHash);
    }

    function execute(bytes calldata proof, bytes32[] memory _inputs, address dest, uint256 value, bytes calldata func) public payable returns (bool) {
        require(usePasskey(proof, _inputs), "Invalid passkey");
        _execute(dest, value, func);
        return true;
    }

    function executeBatch(bytes calldata proof, bytes32[] memory _inputs, address[] calldata dest, uint256[] calldata value, bytes[] calldata func) public payable returns (bool) {
        require(usePasskey(proof, _inputs), "Invalid passkey");
        _executeBatch(dest, value, func);
        return true;
    }

    function executeRecovery(bytes calldata proof, bytes32[] memory _inputs, bytes memory _passkeyInputs) public payable returns (bool) {
        require(useRecovery(proof, _inputs), "Invalid recovery");
        changePasskeyInputs(_passkeyInputs);
        return true;
    }

    function executeNative(bytes calldata proof, bytes32[] memory _inputs, address dest, uint256 value, bytes calldata func, uint256 baseFees, uint256 expectedFees) public payable onlyValeriumForwarder returns (bool) {
        require(address(this).balance >= expectedFees, "Not enough fees");
        
        uint256 gas = gasleft();
        execute(proof, _inputs, dest, value, func);
        uint256 gasUsed = gas - gasleft();
        uint256 fees = (gasUsed * tx.gasprice) + baseFees;

        payable(VALERIUM_GAS_TANK).transfer(fees);
        return true;
    }

    function executeBatchNative(bytes calldata proof, bytes32[] memory _inputs, address[] calldata dest, uint256[] calldata value, bytes[] calldata func, uint256 baseFees, uint256 expectedFees) public payable onlyValeriumForwarder returns (bool) {
        require(address(this).balance >= expectedFees, "Not enough fees");
        
        uint256 gas = gasleft();
        executeBatch(proof, _inputs, dest, value, func);
        uint256 gasUsed = gas - gasleft();
        uint256 fees = (gasUsed * tx.gasprice) + baseFees;

        payable(VALERIUM_GAS_TANK).transfer(fees);
        return true;
    }

    function _execute(address dest, uint256 value, bytes calldata func) internal {
        _call(dest, value, func);
    }

    function _executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) internal {
        require(dest.length == func.length && (value.length == 0 || value.length == func.length), "wrong array lengths");
        if (value.length == 0) {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], 0, func[i]);
            }
        } else {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], value[i], func[i]);
            }
        }
    }

	function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

	receive() external payable {}

    fallback() external payable {}
}