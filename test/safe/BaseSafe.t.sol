// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { BaseTest } from "../Base.t.sol";

import { SafeCreditAccountFactory } from "../../src/safe/CreditAccountFactory.sol";

import { TestAccount, TestAccountLib } from "../libraries/TestAccountLib.t.sol";

// Safe contracts
import { SafeProxyFactory } from
    "@safe-global/safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import { Safe } from "@safe-global/safe-contracts/contracts/Safe.sol";
import { MultiSendCallOnly } from
    "@safe-global/safe-contracts/contracts/libraries/MultiSendCallOnly.sol";

contract BaseSafeTest is BaseTest {
    /*//////////////////////////////////////////////////////////////
                            CONTRACTS
    //////////////////////////////////////////////////////////////*/

    SafeProxyFactory public safeProxyFactory;
    Safe public safeSingleton;
    MultiSendCallOnly public multiSendCallOnly;

    address public gearboxCreditManager;

    SafeCreditAccountFactory public safeCreditAccountFactory;

    /*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

    TestAccount public alice;
    TestAccount public bob;

    address public fabricOwner;

    /*//////////////////////////////////////////////////////////////
                            SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        safeProxyFactory = new SafeProxyFactory();
        safeSingleton = new Safe();
        multiSendCallOnly = new MultiSendCallOnly();

        fabricOwner = makeAddr("fabric_owner");

        gearboxCreditManager = makeAddr("gearbox_credit_manager");

        safeCreditAccountFactory = new SafeCreditAccountFactory(
            fabricOwner,
            address(safeProxyFactory),
            address(safeSingleton),
            address(multiSendCallOnly),
            gearboxCreditManager
        );

        alice = TestAccountLib.createTestAccount("Alice");
    }

    function _makeSafe_1_1_Instance(address owner) internal returns (Safe) {
        address[] memory owners = new address[](1);
        owners[0] = owner;

        return Safe(payable(safeCreditAccountFactory.deployCreditAccount(owners, 1)));
    }
}
