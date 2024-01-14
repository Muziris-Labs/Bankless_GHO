//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../verifier/PasskeyVerifier.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../util/Conversion.sol";

contract PasskeyManager {
    UltraVerifier public passkeyVerifier;

    bytes private inputs;

    uint256 private passkeyNonce;

    error InvalidAuthenticatorData();
    error InvalidClientData();

    constructor(address _passkeyVerifier, bytes memory _passkeyInputs) {
        passkeyVerifier = UltraVerifier(_passkeyVerifier);
        inputs = _passkeyInputs;
    }

    function getPasskeyNonce() public view returns (string memory) {
        return Strings.toString(passkeyNonce);
    }

    function _usePasskeyNonce() internal returns (string memory) {
        passkeyNonce++;
        return Strings.toString(passkeyNonce);
    }

    function getCredentialId() public view returns (string memory) {
        (,string memory credentialId, , , , ) = decodeEncodedInputs(inputs);
        return credentialId;
    }

    function changePasskeyVerifier(address _passkeyVerifier) internal {
        passkeyVerifier = UltraVerifier(_passkeyVerifier);
    }

    function changePasskeyInputs(bytes memory _passkeyInputs) internal {
        inputs = _passkeyInputs;
    }

    function verifyPasskey(bytes calldata proof, bytes32[] memory _inputs) public view returns (bool) {
        bytes32[32] memory messageInput;
        bytes32[32] memory pubkeyHashInput;

        for (uint256 i = 0; i < 32; i++) {
            messageInput[i] = inputs[i];
        }

        for (uint256 i = 0; i < 32; i++) {
            pubkeyHashInput[i] = inputs[i + 32];
        }

        bytes32 expectedMessage = Conversion.convertBytes32ArrayToBytes32(messageInput);
        bytes32 expectedPubkeyHash = Conversion.convertBytes32ArrayToBytes32(pubkeyHashInput);

        bytes32 message = getMessage();
        (
            bytes32 pubkeyHash,,,,,
        ) = decodeEncodedInputs(inputs);

        require(message == expectedMessage, "Invalid message");
        require(pubkeyHash == expectedPubkeyHash, "Invalid pubkeyHash");

        return passkeyVerifier.verify(proof, _inputs);
    }

    function usePasskey(bytes calldata proof, bytes32[] memory _inputs) internal returns (bool) {
        require(verifyPasskey(proof, _inputs), "Invalid passkey");
        _usePasskeyNonce();
        return true;
    }

    function getMessage() public view returns (bytes32) {
        (
            ,
            ,
            bytes memory authenticatorData,
            bytes1 authenticatorDataFlagMask,
            bytes memory clientData,
            uint clientChallengeDataOffset
        ) = decodeEncodedInputs(inputs);

        return
            computeMessage(
                authenticatorData,
                authenticatorDataFlagMask,
                clientData,
                getPasskeyNonce(),
                clientChallengeDataOffset
            );
    }

    function decodeEncodedInputs(
        bytes memory _inputs
    )
        public
        pure
        returns (bytes32 ,string memory, bytes memory, bytes1, bytes memory, uint)
    {
        (
            bytes32 pubkeyHash,
            string memory credentialId,
            bytes memory authenticatorData,
            bytes1 authenticatorDataFlagMask,
            bytes memory clientData,
            uint clientChallengeDataOffset
        ) = abi.decode(_inputs, (bytes32, string, bytes, bytes1, bytes, uint));

        return (
            pubkeyHash,
            credentialId,
            authenticatorData,
            authenticatorDataFlagMask,
            clientData,
            clientChallengeDataOffset
        );
    }

    function computeMessage(
        bytes memory authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes memory clientData,
        string memory clientChallenge,
        uint clientChallengeDataOffset
    ) public pure returns (bytes32) {
        if (
            (authenticatorData[32] & authenticatorDataFlagMask) !=
            authenticatorDataFlagMask
        ) {
            revert InvalidAuthenticatorData();
        }

        bytes memory challengeExtracted = new bytes(
            bytes(clientChallenge).length
        );

        copyBytes(
            clientData,
            clientChallengeDataOffset,
            challengeExtracted.length,
            challengeExtracted,
            0
        );

        if (
            keccak256(abi.encodePacked(bytes(clientChallenge))) !=
            keccak256(abi.encodePacked(challengeExtracted))
        ) {
            revert InvalidClientData();
        }

        bytes memory verifyData = new bytes(authenticatorData.length + 32);

        copyBytes(
            authenticatorData,
            0,
            authenticatorData.length,
            verifyData,
            0
        );

        copyBytes(
            abi.encodePacked(sha256(clientData)),
            0,
            32,
            verifyData,
            authenticatorData.length
        );

        return (sha256(verifyData));
    }

    function copyBytes(
        bytes memory _from,
        uint _fromOffset,
        uint _length,
        bytes memory _to,
        uint _toOffset
    ) internal pure returns (bytes memory _copiedBytes) {
        uint minLength = _length + _toOffset;
        require(_to.length >= minLength);
        uint i = 32 + _fromOffset; 
        uint j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }
}