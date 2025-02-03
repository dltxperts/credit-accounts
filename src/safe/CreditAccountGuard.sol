pragma solidity ^0.8.24;

import { Enum, ISafe } from "./interfaces/ISafe.sol";
import { ITransactionGuard, IERC165 } from "./interfaces/ITransactionGuard.sol";
import { Call } from "../DataTypes.sol";
import { MultiSendLib } from "./libraries/MultiSendLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICreditFacadeHooks } from "../interfaces/ICreditFacadeHooks.sol";
import { ICreditManagerV3 } from
    "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";

import {
    DelegateCallNotAllowedException,
    AccountModificationNotAllowedException
} from "../interfaces/ICreditAccountExceptions.sol";

contract SafeCreditAccountGuard is ITransactionGuard {
    struct Approval {
        address token;
        address spender;
    }

    struct TxContext {
        Approval[] approvals;
    }

    address public immutable MULTISEND_CALL_ONLY;
    address public immutable CREDIT_FACADE;

    bytes4 public constant APPROVE_SELECTOR = bytes4(keccak256("approve(address,uint256)"));

    TxContext internal _txContext;

    constructor(address multisendCallOnly, address _creditManager) {
        MULTISEND_CALL_ONLY = multisendCallOnly;
        CREDIT_FACADE = ICreditManagerV3(_creditManager).creditFacade();
    }

    // Non-reentrant
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
        ISafe safe = ISafe(msg.sender);

        // Allow only delegate calls to the MultiSendCallOnly contract
        if (operation == Enum.Operation.DelegateCall) {
            if (to != MULTISEND_CALL_ONLY) {
                revert DelegateCallNotAllowedException();
            }

            // scan approvals
            Call[] memory calls = MultiSendLib.decodeMultisend(data);
            for (uint256 i = 0; i < calls.length; i++) {
                _handleCall(calls[i]);
            }
        } else {
            _handleCall(Call({ to: to, value: value, data: data }));
        }

        // preCollateralCheck
        bytes memory callData = abi.encodeCall(ICreditFacadeHooks.preExecutionCheck, ());
        bool success =
            safe.execTransactionFromModule(CREDIT_FACADE, 0, callData, Enum.Operation.Call);
        if (!success) {
            revert("preExecutionCheck failed");
        }
    }

    function checkAfterExecution(bytes32 txHash, bool success) external override {
        ISafe safe = ISafe(msg.sender);

        // reset approvals
        for (uint256 i = 0; i < _txContext.approvals.length; i++) {
            Approval memory approval = _txContext.approvals[i];
            IERC20(approval.token).approve(approval.spender, 0);
        }

        // release approvals
        _clearTxContext();

        // postCollateralCheck
        bytes memory callData = abi.encodeCall(ICreditFacadeHooks.postExecutionCheck, ());
        bool success =
            safe.execTransactionFromModule(CREDIT_FACADE, 0, callData, Enum.Operation.Call);
        if (!success) {
            revert("postExecutionCheck failed");
        }
    }

    function _clearTxContext() internal {
        delete _txContext;
    }

    function _handleCall(Call memory call) internal {
        bytes memory callData = call.data;
        if (callData.length > 4) {
            bytes4 selector = bytes4(callData);

            // handle approve
            if (selector == APPROVE_SELECTOR) {
                address spender;
                assembly ("memory-safe") {
                    spender := mload(add(callData, 36))
                }

                _txContext.approvals.push(Approval({ token: call.to, spender: spender }));
            }

            // handle setGuard, enableModule, disableModule, setModuleGuard,setFallbackHandler
            if (
                selector == ISafe.setGuard.selector || selector == ISafe.enableModule.selector
                    || selector == ISafe.disableModule.selector
                    || selector == ISafe.setModuleGuard.selector
                    || selector == ISafe.setFallbackHandler.selector
            ) {
                revert AccountModificationNotAllowedException();
            }
        }
    }

    /// @dev IERC165
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaceId == type(ITransactionGuard).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    function decodeMultisend(bytes memory transactions)
        external
        pure
        returns (Call[] memory calls)
    {
        return MultiSendLib.decodeMultisend(transactions);
    }
}
