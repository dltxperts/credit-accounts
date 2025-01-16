pragma solidity ^0.8.24;

import { Enum } from "./interfaces/ISafe.sol";
import { ITransactionGuard, IERC165 } from "./interfaces/ITransactionGuard.sol";

contract SafeCreditAccountGuard is ITransactionGuard {
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
}
