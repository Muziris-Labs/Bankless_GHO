//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../verifier/RecoveryVerifier.sol";
import "../util/Conversion.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RecoveryManager {
    using ECDSA for bytes32;

    RecoveryUltraVerifier public recoveryVerifier;

    bytes32 private recoveryKeyHash;

    uint256 private recoveryNonce;

    function _initializeRecoveryManager(address _recoveryVerifier, bytes32 _recoveryKeyHash) internal {
        recoveryVerifier = RecoveryUltraVerifier(_recoveryVerifier);
        recoveryKeyHash = _recoveryKeyHash;
    }

    function getRecoveryNonce() public view returns (string memory) {
        return Strings.toString(recoveryNonce);
    }

    function _useRecoveryNonce() internal returns (string memory) {
        recoveryNonce++;
        return Strings.toString(recoveryNonce);
    }

    function hashMessage(string memory message) public pure returns (bytes32) {
        string memory messagePrefix = "\x19Ethereum Signed Message:\n";

        string memory lengthString = Strings.toString(bytes(message).length);

        string memory concatenatedMessage = string(abi.encodePacked(messagePrefix, lengthString, message));

        return keccak256(bytes(concatenatedMessage));
    }

    function changeRecoveryVerifier(address _recoveryVerifier) internal {
        recoveryVerifier = RecoveryUltraVerifier(_recoveryVerifier);
    }

    function verifyRecovery(bytes calldata proof) public view returns (bool) {
        bytes32 message = hashMessage(getRecoveryNonce());

        bytes32[] memory _inputs = Conversion.convertInputs(message, recoveryKeyHash);

        return recoveryVerifier.verify(proof, _inputs);
    }

    function useRecovery(bytes calldata proof) internal returns (bool) {
        require(verifyRecovery(proof), "Invalid recovery");
        _useRecoveryNonce();
        return true;
    }

}