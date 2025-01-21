pragma solidity ^0.8.24;

import { Enum } from "./interfaces/ISafe.sol";
import { ITransactionGuard, IERC165 } from "./interfaces/ITransactionGuard.sol";
import { Call } from "../DataTypes.sol";

import { console2 } from "forge-std/console2.sol";

contract SafeCreditAccountGuard is ITransactionGuard {
    // struct GuardInitData {
    //     address
    // }

    constructor() { }

    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    )
        external
        override
    {
        // MultisendCallOnly
        // check account modification and updates
        // check approvals

        // preCollateralCheck
    }

    function checkAfterExecution(bytes32 txHash, bool success) external override {
        // release approvals

        // collateral check -> external call from module

        // postCollateralCheck
    }

    /// @dev IERC165
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaceId == type(ITransactionGuard).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    /// @dev Modified from Safe MultiSend.sol
    /// Each call is encoded as a packed bytes of
    /// operation has to be uint8(0) in this version (=> 1 byte),
    /// to as a address (=> 20 bytes),
    /// value as a uint256 (=> 32 bytes),
    /// data length as a uint256 (=> 32 bytes),
    /// data as bytes
    function _decodeMultisend(bytes memory transactions)
        internal
        pure
        returns (Call[] memory calls)
    {
        assembly ("memory-safe") {
            let length := mload(transactions)
            let i := 0x20
            let p := mload(0x40) // free memory pointer
            let callsCounter := 0
            // let callsPointer := add(calls, 0x20)
            for {
                // Pre block is not used in "while mode"
            } lt(i, length) {
                // Post block is not used in "while mode"
            } {
                // First byte of the data is the operation.
                // We shift by 248 bits (256 - 8 [operation byte]) it right since mload will always
                // load 32 bytes (a word).
                // This will also zero out unused data.
                let operation := shr(0xf8, mload(add(transactions, i)))
                // We offset the load address by 1 byte (operation byte)
                // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align the
                // data and zero out unused data.
                let to := shr(0x60, mload(add(transactions, add(i, 0x01))))
                // We offset the load address by 21 byte (operation byte + 20 address bytes)
                let value := mload(add(transactions, add(i, 0x15)))
                // We offset the load address by 53 byte (operation byte + 20 address bytes + 32
                // value bytes)
                let dataLengthOffset := add(transactions, add(i, 0x35))
                let dataLength := mload(dataLengthOffset)
                // We offset the load address by 85 byte (operation byte + 20 address bytes + 32
                // value bytes + 32 data length bytes)
                // let data := add(transactions, add(i, 0x55))

                // store the Call in memory
                mstore(p, to) // Call.to
                mstore(add(p, 0x20), value) // Call.value
                mstore(add(p, 0x40), dataLengthOffset) // Call.data

                p := add(p, 0x60)

                // increment the calls counter
                callsCounter := add(callsCounter, 1)
                // callsPointer := add(callsPointer, 0x20)

                // Next entry starts at 85 byte + data length
                i := add(i, add(0x55, dataLength))
            }
            // Store the number of calls
            mstore(p, callsCounter)
            calls := p

            // Calculate the starting pointer for the calls array
            let callsPointer := sub(p, mul(0x60, callsCounter))
            let callsArrayOffset := add(calls, 0x20)

            // Populate the calls array with pointers to each Call struct
            for { let j := 0 } lt(j, callsCounter) { j := add(j, 1) } {
                let callOffset := mul(j, 0x60)
                mstore(add(callsArrayOffset, mul(j, 0x20)), add(callsPointer, callOffset))
            }

            // Update the free memory pointer
            let newFreeMemoryPointer := add(p, add(mul(0x20, callsCounter), 0x20))
            mstore(0x40, newFreeMemoryPointer)
        }
    }

    function decodeMultisend(bytes memory transactions)
        external
        pure
        returns (Call[] memory calls)
    {
        return _decodeMultisend(transactions);
    }
}
