// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { BaseSafeTest } from "./BaseSafe.t.sol";
import { SafeCreditAccountFactory } from "../../src/safe/SafeCreditAccountFactory.sol";

contract SafeCreditAccountTest is BaseSafeTest {
    /*//////////////////////////////////////////////////////////////
                            CONTRACTS
    //////////////////////////////////////////////////////////////*/

    SafeCreditAccountFactory public safeCreditAccountFactory;

    /*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public _gearboxCreditManager;

    /*//////////////////////////////////////////////////////////////
                            SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();

        _gearboxCreditManager = makeAddr("gearbox_credit_manager");

        safeCreditAccountFactory = new SafeCreditAccountFactory(
            _fabricOwner,
            address(safeProxyFactory),
            address(safeSingleton),
            address(multiSendCallOnly),
            _gearboxCreditManager
        );
    }

    /*//////////////////////////////////////////////////////////////
                            TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SafeTransferFromWhenTheCallerIsNotACreditManager() external {
        // it should revert the transaction
    }

    function test_SafeTransferFromWhenTheCallerIsACreditManager() external {
        // it should successfully transfer tokens
    }

    function test_ExecuteShouldRevert() external {
        // it should revert
    }
}
