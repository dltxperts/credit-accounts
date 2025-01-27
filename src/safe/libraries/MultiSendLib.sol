// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Enum } from "../interfaces/ISafe.sol";
import { Call } from "../../DataTypes.sol";

library MultiSendLib {
    /// @dev Modified from Safe MultiSend.sol
    /// Each call is encoded as a packed bytes of
    /// operation has to be uint8(0) in this version (=> 1 byte),
    /// to as a address (=> 20 bytes),
    /// value as a uint256 (=> 32 bytes),
    /// data length as a uint256 (=> 32 bytes),
    /// data as bytes
    function decodeMultisend(bytes memory transactions)
        internal
        pure
        returns (Call[] memory calls)
    {
        assembly ("memory-safe") {
            let length := mload(transactions)
            let i := 0x20
            let p := mload(0x40) // free memory pointer
            let callsCounter := 0
            for { } lt(i, length) { } {
                let operation := shr(0xf8, mload(add(transactions, i)))
                let to := shr(0x60, mload(add(transactions, add(i, 0x01))))
                let value := mload(add(transactions, add(i, 0x15)))
                let dataLengthOffset := add(transactions, add(i, 0x35))
                let dataLength := mload(dataLengthOffset)

                mstore(p, to) // Call.to
                mstore(add(p, 0x20), value) // Call.value
                mstore(add(p, 0x40), dataLengthOffset) // Call.data

                p := add(p, 0x60)
                callsCounter := add(callsCounter, 1)
                i := add(i, add(0x55, dataLength))
            }
            mstore(p, callsCounter)
            calls := p

            let callsPointer := sub(p, mul(0x60, callsCounter))
            let callsArrayOffset := add(calls, 0x20)

            for { let j := 0 } lt(j, callsCounter) { j := add(j, 1) } {
                let callOffset := mul(j, 0x60)
                mstore(add(callsArrayOffset, mul(j, 0x20)), add(callsPointer, callOffset))
            }

            let newFreeMemoryPointer := add(p, add(mul(0x20, callsCounter), 0x20))
            mstore(0x40, newFreeMemoryPointer)
        }
    }

    function encodeMultisendCallOnly(Call[] memory calls) internal pure returns (bytes memory) {
        uint256 totalSize = 0;
        for (uint256 i = 0; i < calls.length; i++) {
            // operation + to + value + data lenght + data
            totalSize += 85 + calls[i].data.length;
        }

        bytes memory encodedCalls = new bytes(totalSize);
        uint256 offset = 0;
        for (uint256 i = 0; i < calls.length; i++) {
            bytes memory encodedCall = _encodeCall(calls[i]);
            for (uint256 j = 0; j < encodedCall.length; j++) {
                encodedCalls[offset + j] = encodedCall[j];
            }
            offset += encodedCall.length;
        }
        return encodedCalls;
    }

    /// @dev Encodes an operation for MultiSendCallOnly contract
    function _encodeCall(Call memory call) internal pure returns (bytes memory) {
        return abi.encodePacked(
            uint8(Enum.Operation.Call), call.to, call.value, uint256(call.data.length), call.data
        );
    }
}
