//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./callback/TokenCallbackHandler.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./base/PasskeyManager.sol";
import "./base/RecoveryManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";


contract Valerium is TokenCallbackHandler, Initializable, PasskeyManager, RecoveryManager, ERC2771Context {
    address public VALERIUM_FORWARDER;
    address public VALERIUM_GAS_TANK;
    address public GHO_TOKEN;
    address public GHO_AGGREGATOR;
    address public ETH_AGGREGATOR;

    constructor(address _forwarder, address _gasTank, address _ghoToken, address _ghoAggregator, address _ethAggregator) ERC2771Context(_forwarder) {
        VALERIUM_FORWARDER = _forwarder;
        VALERIUM_GAS_TANK = _gasTank;
        GHO_TOKEN = _ghoToken;
        GHO_AGGREGATOR = _ghoAggregator;
        ETH_AGGREGATOR = _ethAggregator;
    }

    modifier onlyValeriumForwarder() {
        require(msg.sender == VALERIUM_FORWARDER, "Only Valerium Forwarder can call this function");
        _;
    }

    modifier notValeriumForwarder() {
        require(msg.sender != VALERIUM_FORWARDER, "Valerium Forwarder cannot call this function");
        _;
    }

    function initialize(address _passkeyVerifier, bytes memory _passkeyInputs, address _recoveryVerifier, bytes32 _recoveryKeyHash) public virtual initializer {
        _initialize(_passkeyVerifier, _passkeyInputs, _recoveryVerifier, _recoveryKeyHash);
    }


    function _initialize(address _passkeyVerifier, bytes memory _passkeyInputs, address _recoveryVerifier, bytes32 _recoveryKeyHash) internal virtual {
        _initializePasskeyManager(_passkeyVerifier, _passkeyInputs);
        _initializeRecoveryManager(_recoveryVerifier, _recoveryKeyHash);
    }

    function execute(bytes calldata proof, bytes32[] memory _inputs, address dest, uint256 value, bytes calldata func) public payable notValeriumForwarder returns (bool) {
        require(usePasskey(proof, _inputs), "Invalid passkey");
        _execute(dest, value, func);
        return true;
    }

    function executeBatch(bytes calldata proof, bytes32[] memory _inputs, address[] calldata dest, uint256[] calldata value, bytes[] calldata func) public payable notValeriumForwarder returns (bool) {
        require(usePasskey(proof, _inputs), "Invalid passkey");
        _executeBatch(dest, value, func);
        return true;
    }

    function executeRecovery(bytes calldata proof, bytes32[] memory _inputs, bytes memory _passkeyInputs) public payable notValeriumForwarder returns (bool) {
        require(useRecovery(proof, _inputs), "Invalid recovery");
        changePasskeyInputs(_passkeyInputs);
        return true;
    }

    function executeNative(bytes calldata proof, bytes32[] memory _inputs, address dest, uint256 value, bytes calldata func, uint256 baseFees, uint256 expectedFees) public payable onlyValeriumForwarder returns (bool) {
        require(address(this).balance >= expectedFees + value, "Not enough fees");
        
        uint256 gas = gasleft();
        execute(proof, _inputs, dest, value, func);
        uint256 gasUsed = gas - gasleft();
        uint256 fees = (gasUsed * tx.gasprice) + baseFees;

        payable(VALERIUM_GAS_TANK).transfer(fees);
        return true;
    }

    function executeBatchNative(bytes calldata proof, bytes32[] memory _inputs, address[] calldata dest, uint256[] calldata value, bytes[] calldata func, uint256 baseFees, uint256 expectedFees) public payable onlyValeriumForwarder returns (bool) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < value.length; i++) {
            totalValue += value[i];
        }
        require(address(this).balance >= expectedFees + totalValue, "Not enough fees");
        
        uint256 gas = gasleft();
        executeBatch(proof, _inputs, dest, value, func);
        uint256 gasUsed = gas - gasleft();
        uint256 fees = (gasUsed * tx.gasprice) + baseFees;

        payable(VALERIUM_GAS_TANK).transfer(fees);
        return true;
    }

    function executeRecoveryNative(bytes calldata proof, bytes32[] memory _inputs, bytes memory _passkeyInputs, uint256 baseFees, uint256 expectedFees) public payable onlyValeriumForwarder returns (bool) {
        require(address(this).balance >= expectedFees, "Not enough fees");
        
        uint256 gas = gasleft();
        executeRecovery(proof, _inputs, _passkeyInputs);
        uint256 gasUsed = gas - gasleft();
        uint256 fees = (gasUsed * tx.gasprice) + baseFees;

        payable(VALERIUM_GAS_TANK).transfer(fees);
        return true;
    }

    function getGHOAmount(int256 fees) public view returns (int256) {
        AggregatorV3Interface ethAggregator = AggregatorV3Interface(ETH_AGGREGATOR);
        AggregatorV3Interface ghoAggregator = AggregatorV3Interface(GHO_AGGREGATOR);

        (, int256 ethPrice, , , ) = ethAggregator.latestRoundData();
        (, int256 ghoPrice, , , ) = ghoAggregator.latestRoundData();

        int256 ratio = ethPrice / ghoPrice;

        int256 feeRatio = fees * ratio;
        return feeRatio;
    }

    function executePayGHO(bytes calldata proof, bytes32[] memory _inputs, address dest, uint256 value, bytes calldata func, uint256 baseFees, uint256 expectedFees) public payable onlyValeriumForwarder returns (bool) {
        require(IERC20(GHO_TOKEN).balanceOf(address(this)) >= uint(getGHOAmount(int(expectedFees))), "Not enough fees");
        
        uint256 gas = gasleft();
        execute(proof, _inputs, dest, value, func);
        uint256 gasUsed = gas - gasleft();
        uint256 fees = (gasUsed * tx.gasprice) + baseFees;

        uint256 ghoAmount = uint(getGHOAmount(int(fees)));
        IERC20(GHO_TOKEN).transfer(VALERIUM_GAS_TANK, ghoAmount);
        return true;
    }

    function executeBatchPayGHO(bytes calldata proof, bytes32[] memory _inputs, address[] calldata dest, uint256[] calldata value, bytes[] calldata func, uint256 baseFees, uint256 expectedFees) public payable onlyValeriumForwarder returns (bool) {
        require(IERC20(GHO_TOKEN).balanceOf(address(this)) >= uint(getGHOAmount(int(expectedFees))), "Not enough fees");
        
        uint256 gas = gasleft();
        executeBatch(proof, _inputs, dest, value, func);
        uint256 gasUsed = gas - gasleft();
        uint256 fees = (gasUsed * tx.gasprice) + baseFees;

        uint256 ghoAmount = uint(getGHOAmount(int(fees)));
        IERC20(GHO_TOKEN).transfer(VALERIUM_GAS_TANK, ghoAmount);
        return true;
    }

    function executeRecoveryPayGHO(bytes calldata proof, bytes32[] memory _inputs, bytes memory _passkeyInputs, uint256 baseFees, uint256 expectedFees) public payable onlyValeriumForwarder returns (bool) {
        require(IERC20(GHO_TOKEN).balanceOf(address(this)) >= uint(getGHOAmount(int(expectedFees))), "Not enough fees");
        
        uint256 gas = gasleft();
        executeRecovery(proof, _inputs, _passkeyInputs);
        uint256 gasUsed = gas - gasleft();
        uint256 fees = (gasUsed * tx.gasprice) + baseFees;

        uint256 ghoAmount = uint(getGHOAmount(int(fees)));
        IERC20(GHO_TOKEN).transfer(VALERIUM_GAS_TANK, ghoAmount);
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