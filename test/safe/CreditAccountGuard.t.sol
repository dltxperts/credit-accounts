// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { BaseSafeTest } from "./BaseSafe.t.sol";
import { Call } from "../../src/DataTypes.sol";
import { MultiSendLib } from "../../src/safe/libraries/MultiSendLib.sol";

// Forge
import { console2 } from "forge-std/console2.sol";

// Safe contracts
import { Safe } from "@safe-global/safe-contracts/contracts/Safe.sol";
import { Enum } from "@safe-global/safe-contracts/contracts/common/Enum.sol";
import { Guard, GuardManager } from "@safe-global/safe-contracts/contracts/base/GuardManager.sol";
import { MultiSendCallOnly } from
    "@safe-global/safe-contracts/contracts/libraries/MultiSendCallOnly.sol";

import {
    DelegateCallNotAllowedException,
    AccountModificationNotAllowedException
} from "../../src/interfaces/ICreditAccountExceptions.sol";

// Helpers
import { SafeLib } from "../libraries/SafeLib.t.sol";
import { TestAccount } from "../libraries/TestAccountLib.t.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Test contracts
import { SafeCreditAccountGuard } from "../../src/safe/CreditAccountGuard.sol";
import { CreditManagerTrait } from "../../src/safe/CreditManagerTrait.sol";

contract MockCreditAccountGuard is SafeCreditAccountGuard {
    constructor(
        address multisendCallOnly,
        address creditManager
    )
        CreditManagerTrait(creditManager)
        SafeCreditAccountGuard(multisendCallOnly)
    { }

    function getApprovals() external view returns (SafeCreditAccountGuard.Approval[] memory) {
        return _txContext.approvals;
    }
}

contract MockSafe {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    )
        external
        returns (bool)
    {
        (bool success,) = to.call(data);

        return success;
    }
}

contract SafeCreditAccountGuardTest is BaseSafeTest {
    using SafeLib for Safe;

    /*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

    Guard public guard;
    MockERC20 public token;
    address public creditAccount;

    /*//////////////////////////////////////////////////////////////
                            SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();

        // creditAccount = _makeSafe_1_1_Instance(alice.addr);
        creditAccount = address(new MockSafe());
        guard = Guard(
            address(new MockCreditAccountGuard(address(multiSendCallOnly), gearboxCreditManager))
        );
        token = new MockERC20();
    }

    function _checkTransaction(address to, bytes memory data, Enum.Operation operation) internal {
        guard.checkTransaction(
            to, 0, data, operation, 0, 0, 0, address(0), payable(0), "", alice.addr
        );
    }

    /*//////////////////////////////////////////////////////////////
                            TESTS
    //////////////////////////////////////////////////////////////*/

    function test_WhenDelegateCallIsNotToMultiSendCallOnly() external {
        // it should revert with error

        TestAccount[] memory signers = new TestAccount[](1);
        signers[0] = alice;

        address anotherMultiSend = address(new MultiSendCallOnly());

        vm.startPrank(address(creditAccount));
        vm.expectRevert(DelegateCallNotAllowedException.selector);
        _checkTransaction(anotherMultiSend, "", Enum.Operation.DelegateCall);
        vm.stopPrank();
    }

    modifier whenApproving() {
        _;
    }

    function test_GivenSingleApproval() external whenApproving {
        // it should record approval

        address spender = makeAddr("spender");
        bytes memory data = abi.encodeCall(IERC20.approve, (spender, 100));
        vm.startPrank(address(creditAccount));
        _checkTransaction(address(token), data, Enum.Operation.Call);
        vm.stopPrank();

        SafeCreditAccountGuard.Approval[] memory approvals =
            MockCreditAccountGuard(address(guard)).getApprovals();
        assertEq(approvals.length, 1);
        assertEq(approvals[0].token, address(token));
        assertEq(approvals[0].spender, spender);
    }

    function test_GivenMultipleApprovals() external whenApproving {
        // it should record all

        address spender1 = makeAddr("spender1");
        address spender2 = makeAddr("spender2");

        Call[] memory calls = new Call[](2);
        calls[0] = Call({
            to: address(token),
            value: 0,
            data: abi.encodeCall(IERC20.approve, (spender1, 100))
        });
        calls[1] = Call({
            to: address(token),
            value: 0,
            data: abi.encodeCall(IERC20.approve, (spender2, 100))
        });

        bytes memory data = MultiSendLib.encodeMultisendCallOnly(calls);
        vm.startPrank(address(creditAccount));
        _checkTransaction(address(multiSendCallOnly), data, Enum.Operation.DelegateCall);
        vm.stopPrank();

        SafeCreditAccountGuard.Approval[] memory approvals =
            MockCreditAccountGuard(address(guard)).getApprovals();
        assertEq(approvals.length, 2);
        assertEq(approvals[0].token, address(token));
        assertEq(approvals[0].spender, spender1);
        assertEq(approvals[1].spender, spender2);
    }

    modifier whenProhibitedOperations() {
        _;
    }

    function test_GivenSetGuardIsCalled() external whenProhibitedOperations {
        // it should revert with error

        // direct call
        {
            bytes memory data = abi.encodeCall(GuardManager.setGuard, (address(guard)));
            vm.expectRevert(AccountModificationNotAllowedException.selector);
            _checkTransaction(address(creditAccount), data, Enum.Operation.Call);
        }

        // delegate call
        {
            bytes memory data = abi.encodeCall(GuardManager.setGuard, (address(guard)));
            Call[] memory calls = new Call[](1);
            calls[0] = Call({ to: address(multiSendCallOnly), value: 0, data: data });
            bytes memory encodedCalls = MultiSendLib.encodeMultisendCallOnly(calls);
            vm.expectRevert(AccountModificationNotAllowedException.selector);
            _checkTransaction(address(multiSendCallOnly), encodedCalls, Enum.Operation.DelegateCall);
        }
    }

    function test_GivenEnableModuleIsCalled() external whenProhibitedOperations {
        // it should revert with error
    }

    function test_GivenDisableModuleIsCalled() external whenProhibitedOperations {
        // it should revert with error
    }

    function test_GivenSetModuleGuardIsCalled() external whenProhibitedOperations {
        // it should revert with error
    }

    function test_GivenSetFallbackHandlerIsCalled() external whenProhibitedOperations {
        // it should revert with error
    }
}
