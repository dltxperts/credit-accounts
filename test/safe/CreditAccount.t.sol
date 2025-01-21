// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { BaseSafeTest } from "./BaseSafe.t.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeCreditAccountFactory } from "../../src/safe/SafeCreditAccountFactory.sol";
import { SafeCreditAccount } from "../../src/safe/SafeCreditAccount.sol";
import {
    CallerNotCreditManagerException,
    NotImplementedException
} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";
import { ICreditAccountV3 } from
    "@gearbox-protocol/core-v3/contracts/interfaces/ICreditAccountV3.sol";

import { Enum } from "../../src/safe/interfaces/ISafe.sol";
import { Call } from "../../src/DataTypes.sol";

import { console2 } from "forge-std/console2.sol";

contract SafeCreditAccountTest is BaseSafeTest {
    /*//////////////////////////////////////////////////////////////
                            CONTRACTS
    //////////////////////////////////////////////////////////////*/

    SafeCreditAccountFactory public safeCreditAccountFactory;
    MockERC20 public mockERC20;

    /*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public _gearboxCreditManager;

    /*//////////////////////////////////////////////////////////////
                            SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();

        mockERC20 = new MockERC20();

        _gearboxCreditManager = makeAddr("gearbox_credit_manager");

        safeCreditAccountFactory = new SafeCreditAccountFactory(
            fabricOwner,
            address(safeProxyFactory),
            address(safeSingleton),
            address(multiSendCallOnly),
            _gearboxCreditManager
        );
    }

    function _makeSafe_1_1_Instance() internal returns (address) {
        address[] memory owners = new address[](1);
        owners[0] = accountOwners[0];

        return safeCreditAccountFactory.deployCreditAccount(owners, 1);
    }

    /*//////////////////////////////////////////////////////////////
                            TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SafeTransferFromWhenTheCallerIsNotACreditManager() external {
        // it should revert the transaction
        address safeCreditAccount = _makeSafe_1_1_Instance();

        vm.expectRevert(CallerNotCreditManagerException.selector);

        address fakeCreditManager = makeAddr("fake_credit_manager");
        vm.prank(fakeCreditManager);
        ICreditAccountV3(safeCreditAccount).safeTransfer(address(mockERC20), makeAddr("to"), 100);
    }

    function test_SafeTransferFromWhenTheCallerIsACreditManager() external {
        // it should successfully transfer tokens
        address safeCreditAccount = _makeSafe_1_1_Instance();
        address to = makeAddr("to");

        mockERC20.mint(safeCreditAccount, 100);

        vm.prank(_gearboxCreditManager);
        ICreditAccountV3(safeCreditAccount).safeTransfer(address(mockERC20), to, 100);

        assertEq(mockERC20.balanceOf(to), 100);
        assertEq(mockERC20.balanceOf(safeCreditAccount), 0);
    }

    function test_ExecuteShouldRevert() external {
        // it should revert
        address safeCreditAccount = _makeSafe_1_1_Instance();

        vm.expectRevert(NotImplementedException.selector);
        ICreditAccountV3(safeCreditAccount).execute(makeAddr("target"), "data");
    }

    function test_DecodeMultisend() external {
        address safeCreditAccount = _makeSafe_1_1_Instance();

        address target = makeAddr("target");
        bytes memory dummyCall = abi.encodeCall(IERC20.transfer, (target, 100));
        console2.log("dummyCall", dummyCall.length, target);

        bytes memory op1 = abi.encodePacked(
            uint8(Enum.Operation.Call), target, uint256(1), uint256(dummyCall.length), dummyCall
        );
        bytes memory op2 = abi.encodePacked(
            uint8(Enum.Operation.Call), target, uint256(2), uint256(dummyCall.length), dummyCall
        );
        bytes memory data = abi.encodePacked(op1, op2);

        Call[] memory calls = SafeCreditAccount(safeCreditAccount).decodeMultisend(data);

        assertEq(calls.length, 2);
        assertEq(calls[0].to, target);
        assertEq(calls[0].value, 1);
        assertEq(calls[1].to, target);
        assertEq(calls[1].value, 2);
        assertEq(calls[0].data, dummyCall);
        assertEq(calls[1].data, dummyCall);
    }
}
