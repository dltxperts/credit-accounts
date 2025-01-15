pragma solidity ^0.8.24;

import {ITransactionGuard} from "@safe-global/safe-contracts/contracts/base/GuardManager.sol";

contract SafeCreditAccountGuard is ITransactionGuard {
    // multicall
    // credit manager
    //
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
    ) external {
        // check delegate call
        // check account modification and updates
        // check approvals
    }

    function checkAfterExecution(bytes32 txHash, bool success) external {
        // release approvals

        // collateral check -> external call from module
    }
}
