//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./callback/TokenCallbackHandler.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Valerium is TokenCallbackHandler, Initializable {

	

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