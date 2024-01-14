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

    function verifyRecovery(bytes calldata proof, bytes32[] memory _inputs) public view returns (bool) {
        bytes32[32] memory messageInput;
        bytes32[32] memory pubkeyHashInput;

        for (uint256 i = 0; i < 32; i++) {
            messageInput[i] = bytes32(uint256(recoveryKeyHash) >> (i * 8));
        }

        for (uint256 i = 0; i < 32; i++) {
            pubkeyHashInput[i] = bytes32(uint256(recoveryKeyHash) >> ((i + 32) * 8));
        }

        bytes32 expectedMessage = Conversion.convertBytes32ArrayToBytes32(messageInput);
        bytes32 expectedPubkeyHash = Conversion.convertBytes32ArrayToBytes32(pubkeyHashInput);

        bytes32 message = getRecoveryNonce();

        require(message == expectedMessage, "Invalid message");
        require(recoveryKeyHash == expectedPubkeyHash, "Invalid pubkeyHash");

        return recoveryVerifier.verify(proof, _inputs);
    }

    function useRecovery(bytes calldata proof, bytes32[] memory _inputs) public returns (bool) {
        require(verifyRecovery(proof, _inputs), "Invalid recovery");
        _useRecoveryNonce();
        return true;
    }

}