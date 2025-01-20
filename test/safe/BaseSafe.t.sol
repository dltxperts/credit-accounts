// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { BaseTest } from "../Base.t.sol";

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

    /*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

    address[] public accountOwners;
    address public fabricOwner;

    /*//////////////////////////////////////////////////////////////
                            SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        safeProxyFactory = new SafeProxyFactory();
        safeSingleton = new Safe();
        multiSendCallOnly = new MultiSendCallOnly();

        accountOwners = new address[](3);
        accountOwners[0] = makeAddr("owner_0");
        accountOwners[1] = makeAddr("owner_1");
        accountOwners[2] = makeAddr("owner_2");

        fabricOwner = makeAddr("fabric_owner");
    }
}
