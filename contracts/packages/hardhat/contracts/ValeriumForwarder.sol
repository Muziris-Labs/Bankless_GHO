//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./ValeriumFactory.sol";
import "./Valerium.sol";

abstract contract Nonces {
    /**
     * @dev The nonce used for an `account` is not the expected current nonce.
     */
    error InvalidAccountNonce(address account, uint256 currentNonce);

    mapping(address => uint256) private _nonces;

    /**
     * @dev Returns the next unused nonce for an address.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(address owner) internal virtual returns (uint256) {
        // For each account, the nonce has an initial value of 0, can only be incremented by one, and cannot be
        // decremented or reset. This guarantees that the nonce never overflows.
        unchecked {
            // It is important to do x++ and not ++x here.
            return _nonces[owner]++;
        }
    }

    /**
     * @dev Same as {_useNonce} but checking that `nonce` is the next valid for `owner`.
     */
    function _useCheckedNonce(address owner, uint256 nonce) internal virtual {
        uint256 current = _useNonce(owner);
        if (nonce != current) {
            revert InvalidAccountNonce(owner, current);
        }
    }
}

contract ValeriumForwarder is EIP712, Nonces {
    using ECDSA for bytes32;

    struct ForwardRequestData {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint48 deadline;
        bytes data;
        bytes signature;
    }

    bytes32 internal constant _FORWARD_REQUEST_TYPEHASH =
        keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,uint48 deadline,bytes data)"
        );

    address public owner;

    ValeriumFactory public valeriumFactory;

    modifier onlyOwner() {
        require(msg.sender == owner, "ValeriumForwarder: Only owner can call this function");
        _;
    }

    function assignFactory (address _valeriumFactory) public onlyOwner {
        valeriumFactory = ValeriumFactory(_valeriumFactory);
    }

    /**
     * @dev Emitted when a `ForwardRequest` is executed.
     *
     * NOTE: An unsuccessful forward request could be due to an invalid signature, an expired deadline,
     * or simply a revert in the requested call. The contract guarantees that the relayer is not able to force
     * the requested call to run out of gas.
     */
    event ExecutedForwardRequest(address indexed signer, uint256 nonce, bool success);

    /**
     * @dev The request `from` doesn't match with the recovered `signer`.
     */
    error ERC2771ForwarderInvalidSigner(address signer, address from);

    /** 
     * @dev The `requestedValue` doesn't match with the available `msgValue`.
     */
    error ERC2771ForwarderMismatchedValue(uint256 requestedValue, uint256 msgValue);

    /**
     * @dev The request `deadline` has expired.
     */
    error ERC2771ForwarderExpiredRequest(uint48 deadline);

    /**
     * @dev The request target doesn't trust the `forwarder`.
     */
    error ERC2771UntrustfulTarget(address target, address forwarder);

    /**
     * @dev See {EIP712-constructor}.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev Returns `true` if a request is valid for a provided `signature` at the current block timestamp.
     *
     * A transaction is considered valid when the target trusts this forwarder, the request hasn't expired
     * (deadline is not met), and the signer matches the `from` parameter of the signed request.
     *
     * NOTE: A request may return false here but it won't cause {executeBatch} to revert if a refund
     * receiver is provided.
     */
    function verify(ForwardRequestData calldata request) public view virtual returns (bool) {
        (bool isTrustedForwarder, bool active, bool signerMatch, ) = _validate(request);
        return isTrustedForwarder && active && signerMatch;
    }

    /**
     * @dev Executes a `request` on behalf of `signature`'s signer using the ERC-2771 protocol. The gas
     * provided to the requested call may not be exactly the amount requested, but the call will not run
     * out of gas. Will revert if the request is invalid or the call reverts, in this case the nonce is not consumed.
     *
     * Requirements:
     *
     * - The request value should be equal to the provided `msg.value`.
     * - The request should be valid according to {verify}.
     */
    function execute(ForwardRequestData calldata request, uint256 baseFees, uint256 expectedFees) public payable virtual {
        // We make sure that msg.value and request.value match exactly.
        // If the request is invalid or the call reverts, this whole function
        // will revert, ensuring value isn't stuck.
        if (msg.value != request.value) {
            revert ERC2771ForwarderMismatchedValue(request.value, msg.value);
        }

        if (!_execute(request, true, baseFees, expectedFees)) {
            revert ERC2771ForwarderInvalidSigner(request.from, msg.sender);
        }
    }

    /**
     * @dev Validates if the provided request can be executed at current block timestamp with
     * the given `request.signature` on behalf of `request.signer`.
     */
    function _validate(
        ForwardRequestData calldata request
    ) internal view virtual returns (bool isTrustedForwarder, bool active, bool signerMatch, address signer) {
        (bool isValid, address recovered) = _recoverForwardRequestSigner(request);

        return (
            _isTrustedByTarget(request.to),
            request.deadline >= block.timestamp,
            isValid && recovered == request.from,
            recovered
        );
    }

    /**
     * @dev Returns a tuple with the recovered the signer of an EIP712 forward request message hash
     * and a boolean indicating if the signature is valid.
     *
     * NOTE: The signature is considered valid if {ECDSA-tryRecover} indicates no recover error for it.
     */
    function _recoverForwardRequestSigner(
        ForwardRequestData calldata request
    ) internal view virtual returns (bool, address) {
        (address recovered, ECDSA.RecoverError err ) = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _FORWARD_REQUEST_TYPEHASH,
                    request.from,
                    request.to,
                    request.value,
                    request.gas,
                    nonces(request.from),
                    request.deadline,
                    keccak256(request.data)
                )
            )
        ).tryRecover(request.signature);

        return (err == ECDSA.RecoverError.NoError, recovered);
    }

    /**
     * @dev Validates and executes a signed request returning the request call `success` value.
     *
     * Internal function without msg.value validation.
     *
     * Requirements:
     *
     * - The caller must have provided enough gas to forward with the call.
     * - The request must be valid (see {verify}) if the `requireValidRequest` is true.
     *
     * Emits an {ExecutedForwardRequest} event.
     *
     * IMPORTANT: Using this function doesn't check that all the `msg.value` was sent, potentially
     * leaving value stuck in the contract.
     */
    function _execute(
        ForwardRequestData calldata request,
        bool requireValidRequest,
        uint256 baseFees,
        uint256 expectedFees
    ) internal virtual returns (bool success) {
        (bool isTrustedForwarder, bool active, bool signerMatch, address signer) = _validate(request);

        // Need to explicitly specify if a revert is required since non-reverting is default for
        // batches and reversion is opt-in since it could be useful in some scenarios
        if (requireValidRequest) {
            if (!isTrustedForwarder) {
                revert ERC2771UntrustfulTarget(request.to, address(this));
            }

            if (!active) {
                revert ERC2771ForwarderExpiredRequest(request.deadline);
            }

            if (!signerMatch) {
                revert ERC2771ForwarderInvalidSigner(signer, request.from);
            }
        }

        // Ignore an invalid request because requireValidRequest = false
        if (isTrustedForwarder && signerMatch && active) {
            // Nonce should be used before the call to prevent reusing by reentrancy
            uint256 currentNonce = _useNonce(signer);

            uint256 reqGas = request.gas;
            address to = request.to;
            bytes memory transactionData = request.data;
            bytes memory data = abi.encodePacked(request.data, request.from);

            uint256 gasLeft;

            bytes4 functionSelector;
            assembly {
                functionSelector := mload(add(transactionData, 32))
            }

            if(to == address(valeriumFactory)){
                assembly {
                    success := call(reqGas, to, 0, add(data, 0x20), mload(data), 0, 0) 
                }
            }
            else{
                if(functionSelector == Valerium.executeNative.selector){
                    (bytes memory proof, address dest, uint256 value, bytes memory func, , ) = abi.decode(request.data[4:], (bytes, address, uint256, bytes, uint256, uint256));
                    success = Valerium(payable(request.to)).executeNative(proof, dest, value, func, baseFees, expectedFees);
                }
                else if(functionSelector == Valerium.executeBatchNative.selector){
                    (bytes memory proof, address[] memory dest, uint256[] memory value, bytes[] memory func, , ) = abi.decode(request.data[4:], (bytes, address[], uint256[], bytes[], uint256, uint256));
                    success = Valerium(payable(request.to)).executeBatchNative(proof, dest, value, func, baseFees, expectedFees);
                }
                else if(functionSelector == Valerium.executeRecoveryNative.selector){
                    (bytes memory proof, bytes memory _passkeyInputs, , ) = abi.decode(request.data[4:], (bytes, bytes,uint256, uint256));
                    success = Valerium(payable(request.to)).executeRecoveryNative(proof, _passkeyInputs, baseFees, expectedFees);
                }
                else if(functionSelector == Valerium.executePayGHO.selector){
                    (bytes memory proof, address dest, uint256 value, bytes memory func, , ) = abi.decode(request.data[4:], (bytes, address, uint256, bytes, uint256, uint256));
                    success = Valerium(payable(request.to)).executePayGHO(proof, dest, value, func, baseFees, expectedFees);
                }
                else if(functionSelector == Valerium.executeBatchPayGHO.selector){
                    (bytes memory proof, address[] memory dest, uint256[] memory value, bytes[] memory func, , ) = abi.decode(request.data[4:], (bytes, address[], uint256[], bytes[], uint256, uint256));
                    success = Valerium(payable(request.to)).executeBatchPayGHO(proof, dest, value, func, baseFees, expectedFees);
                }
                else if(functionSelector == Valerium.executeRecoveryPayGHO.selector){
                    (bytes memory proof, bytes memory _passkeyInputs, , ) = abi.decode(request.data[4:], (bytes, bytes,uint256, uint256));
                    success = Valerium(payable(request.to)).executeRecoveryPayGHO(proof, _passkeyInputs, baseFees, expectedFees);
                }
                else{
                    return false;
                }   
            }

            gasLeft = gasleft();

            _checkForwardedGas(gasLeft, request);

            emit ExecutedForwardRequest(signer, currentNonce, success);
        }
    }

    /**
     * @dev Returns whether the target trusts this forwarder.
     *
     * This function performs a static call to the target contract calling the
     * {ERC2771Context-isTrustedForwarder} function.
     */
    function _isTrustedByTarget(address target) private view returns (bool) {
        bytes memory encodedParams = abi.encodeCall(ERC2771Context.isTrustedForwarder, (address(this)));

        bool success;
        uint256 returnSize;
        uint256 returnValue;
        /// @solidity memory-safe-assembly
        assembly {
            // Perform the staticcal and save the result in the scratch space.
            // | Location  | Content  | Content (Hex)                                                      |
            // |-----------|----------|--------------------------------------------------------------------|
            // |           |          |                                                           result ↓ |
            // | 0x00:0x1F | selector | 0x0000000000000000000000000000000000000000000000000000000000000001 |
            success := staticcall(gas(), target, add(encodedParams, 0x20), mload(encodedParams), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }

    /**
     * @dev Checks if the requested gas was correctly forwarded to the callee.
     *
     * As a consequence of https://eips.ethereum.org/EIPS/eip-150[EIP-150]:
     * - At most `gasleft() - floor(gasleft() / 64)` is forwarded to the callee.
     * - At least `floor(gasleft() / 64)` is kept in the caller.
     *
     * It reverts consuming all the available gas if the forwarded gas is not the requested gas.
     *
     * IMPORTANT: The `gasLeft` parameter should be measured exactly at the end of the forwarded call.
     * Any gas consumed in between will make room for bypassing this check.
     */
    function _checkForwardedGas(uint256 gasLeft, ForwardRequestData calldata request) private pure {
        // To avoid insufficient gas griefing attacks, as referenced in https://ronan.eth.limo/blog/ethereum-gas-dangers/
        //
        // A malicious relayer can attempt to shrink the gas forwarded so that the underlying call reverts out-of-gas
        // but the forwarding itself still succeeds. In order to make sure that the subcall received sufficient gas,
        // we will inspect gasleft() after the forwarding.
        //
        // Let X be the gas available before the subcall, such that the subcall gets at most X * 63 / 64.
        // We can't know X after CALL dynamic costs, but we want it to be such that X * 63 / 64 >= req.gas.
        // Let Y be the gas used in the subcall. gasleft() measured immediately after the subcall will be gasleft() = X - Y.
        // If the subcall ran out of gas, then Y = X * 63 / 64 and gasleft() = X - Y = X / 64.
        // Under this assumption req.gas / 63 > gasleft() is true is true if and only if
        // req.gas / 63 > X / 64, or equivalently req.gas > X * 63 / 64.
        // This means that if the subcall runs out of gas we are able to detect that insufficient gas was passed.
        //
        // We will now also see that req.gas / 63 > gasleft() implies that req.gas >= X * 63 / 64.
        // The contract guarantees Y <= req.gas, thus gasleft() = X - Y >= X - req.gas.
        // -    req.gas / 63 > gasleft()
        // -    req.gas / 63 >= X - req.gas
        // -    req.gas >= X * 63 / 64
        // In other words if req.gas < X * 63 / 64 then req.gas / 63 <= gasleft(), thus if the relayer behaves honestly
        // the forwarding does not revert.
        if (gasLeft < request.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.20
            // https://docs.soliditylang.org/en/v0.8.20/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }
    }
}