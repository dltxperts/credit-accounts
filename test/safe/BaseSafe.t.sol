// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { BaseTest } from "../Base.t.sol";
import { MockAddressProvider } from "../mocks/MockAddressProvider.sol";

import { SafeCreditAccountFactory } from "../../src/safe/CreditAccountFactory.sol";

import { TestAccount, TestAccountLib } from "../libraries/TestAccountLib.t.sol";

// Gearbox Contracts
import {
    AP_INSTANCE_MANAGER_PROXY,
    NO_VERSION_CONTROL
} from "@gearbox-protocol/core-v3/contracts/libraries/Constants.sol";

// Safe contracts
import { SafeProxyFactory } from
    "@safe-global/safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import { Safe } from "@safe-global/safe-contracts/contracts/Safe.sol";
import { MultiSendCallOnly } from
    "@safe-global/safe-contracts/contracts/libraries/MultiSendCallOnly.sol";

contract SafeCreditAccountFactoryHarness is SafeCreditAccountFactory {
    constructor(
        address _addressProvider,
        address _safeProxyFactory,
        address _safeSingleton,
        address _multiSendCallOnly
    )
        SafeCreditAccountFactory(
            _addressProvider,
            _safeProxyFactory,
            _safeSingleton,
            _multiSendCallOnly
        )
    { }

    function deployCreditAccount(
        address creditManager,
        address[] memory owners,
        uint256 threshold
    )
        public
        returns (address)
    {
        address safeCreditAccountModule = _creditManagerToSafeAccountModule[creditManager];
        return _deploySafeCreditAccount(safeCreditAccountModule, owners, threshold);
    }

    function getSafeCreditAccountModule(address creditManager) public view returns (address) {
        return _creditManagerToSafeAccountModule[creditManager];
    }
}

contract BaseSafeTest is BaseTest {
    /*//////////////////////////////////////////////////////////////
                            CONTRACTS
    //////////////////////////////////////////////////////////////*/

    SafeProxyFactory public safeProxyFactory;
    Safe public safeSingleton;
    MultiSendCallOnly public multiSendCallOnly;
    SafeCreditAccountFactoryHarness public safeCreditAccountFactory;
    MockAddressProvider public mockAddressProvider;

    /*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public instanceManagerProxy;
    address public gearboxCreditManager;

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
        mockAddressProvider = new MockAddressProvider();

        gearboxCreditManager = makeAddr("gearbox_credit_manager");
        instanceManagerProxy = makeAddr("instance_manager_proxy");
        mockAddressProvider.setAddress(AP_INSTANCE_MANAGER_PROXY, instanceManagerProxy);

        safeCreditAccountFactory = new SafeCreditAccountFactoryHarness(
            address(mockAddressProvider),
            address(safeProxyFactory),
            address(safeSingleton),
            address(multiSendCallOnly)
        );
        safeCreditAccountFactory.addCreditManager(gearboxCreditManager);

        alice = TestAccountLib.createTestAccount("Alice");
    }

    function _makeSafe_1_1_Instance(address owner) internal returns (Safe) {
        address[] memory owners = new address[](1);
        owners[0] = owner;

        return Safe(
            payable(safeCreditAccountFactory.deployCreditAccount(gearboxCreditManager, owners, 1))
        );
    }
}
