//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../verifier/RecoveryVerifier.sol";
import "../util/Conversion.sol";

contract RecoveryManager {
    RecoveryUltraVerifier public recoveryVerifier;

    bytes32 private recoveryKeyHash;

    uint256 private recoveryNonce;

    function _initializeRecoveryManager(address _recoveryVerifier, bytes32 _recoveryKeyHash) internal {
        recoveryVerifier = RecoveryUltraVerifier(_recoveryVerifier);
        recoveryKeyHash = _recoveryKeyHash;
    }

    function getRecoveryNonce() public view returns (bytes32) {
        return bytes32(recoveryNonce);
    }

    function _useRecoveryNonce() internal returns (bytes32) {
        recoveryNonce++;
        return bytes32(recoveryNonce);
    }

    function changeRecoveryVerifier(address _recoveryVerifier) internal {
        recoveryVerifier = RecoveryUltraVerifier(_recoveryVerifier);
    }

    function verifyRecovery(bytes calldata proof) public view returns (bool) {
        bytes32 message = getRecoveryNonce();

        bytes32[] memory _inputs = Conversion.convertInputs(message, recoveryKeyHash);

        return recoveryVerifier.verify(proof, _inputs);
    }

    function useRecovery(bytes calldata proof) public returns (bool) {
        require(verifyRecovery(proof), "Invalid recovery");
        _useRecoveryNonce();
        return true;
    }

}