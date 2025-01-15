pragma solidity ^0.8.24;

// Gearbox
import {ICreditAccountV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditAccountV3.sol";
import {
    NotImplementedException,
    CallerNotCreditManagerException
} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

// Safe
import {ISafe} from "./interfaces/ISafe.sol";
import {HandlerContext} from "@safe-global/safe-contracts/contracts/handler/HandlerContext.sol";

contract SafeCreditAccount is ICreditAccountV3, HandlerContext {
    /// @notice Account factory this account was deployed with
    address public immutable override factory;

    /// @notice Credit manager this account is connected to
    address public immutable override creditManager;

    constructor(address _creditManager) {
        creditManager = _creditManager;
        factory = msg.sender;
    }

    /// @dev Ensures that function caller is credit manager
    modifier creditManagerOnly() {
        _revertIfNotCreditManager();
        _;
    }

    function safeTransfer(address token, address to, uint256 amount) external creditManagerOnly {
        ISafe safe = ISafe(msg.sender);

        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        (bool success, bytes memory returnData) =
            safe.execTransactionFromModuleReturnData(token, 0, data, ISafe.Operation.Call);
        // uint256 returnDataSize = returnData.length;

        // assembly ("memory-safe") {
        //     if success {
        //         switch returnDataSize
        //         case 0 { success := gt(extcodesize(token), 0) }
        //         default { success := and(gt(returnDataSize, 31), eq(mload(0), 1)) }
        //     }
        // }

        // if (!success) revert SafeTransferFailed();
    }

    // credit manager only
    function execute(address target, bytes calldata data) external returns (bytes memory result) {
        revert NotImplementedException();
    }

    function rescue(address target, bytes calldata data) external {
        revert NotImplementedException();
    }

    /// @dev Reverts if `msg.sender` is not credit manager
    function _revertIfNotCreditManager() internal view {
        if (_msgSender() != creditManager) {
            revert CallerNotCreditManagerException();
        }
    }
}
