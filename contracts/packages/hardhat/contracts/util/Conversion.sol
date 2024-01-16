//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Conversion {
    function convertBytes32ArrayToBytes32(bytes32[32] memory value) public pure returns (bytes32) {
        uint[32] memory output;

        for(uint256 i = 0; i < 32; i++){
            output[i] = uint(value[i]);
        }

        return convertUintArrayToBytes32(output);
    }

    function convertUintArrayToBytes32(uint[32] memory byteArray) internal pure returns (bytes32) {
        bytes32 result;

        for (uint256 i = 0; i < 32; i++) {
            result |= bytes32(byteArray[i]) << ((31 - i) * 8);
        }

        return result;
    }
}