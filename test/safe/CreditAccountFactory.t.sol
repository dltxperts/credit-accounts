pragma solidity ^0.8.24;

import { BaseTest } from "../Base.t.sol";
import { console2 } from "forge-std/console2.sol";

import { ISafe } from "../../src/safe/interfaces/ISafe.sol";
import { SafeCreditAccountFactory } from "../../src/safe/CreditAccountFactory.sol";
import { SafeProxyFactory } from
    "@safe-global/safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import { MultiSendCallOnly } from
    "@safe-global/safe-contracts/contracts/libraries/MultiSendCallOnly.sol";
import { Safe } from "@safe-global/safe-contracts/contracts/Safe.sol";
import { GuardManager } from "@safe-global/safe-contracts/contracts/base/GuardManager.sol";
import { ModuleManager } from "@safe-global/safe-contracts/contracts/base/ModuleManager.sol";

contract CreditAccountFactoryTest is BaseTest {
    /*//////////////////////////////////////////////////////////////
                            CONTRACTS
    //////////////////////////////////////////////////////////////*/

    SafeCreditAccountFactory internal safeCreditAccountFactory;
    SafeProxyFactory internal safeProxyFactory;
    Safe internal safeSingleton;
    MultiSendCallOnly internal multiSendCallOnly;

    address constant SENTINEL_MODULES = address(0x1);

    /*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

    address[] _accountOwners;
    address _fabricOwner;
    address _gearboxCreditManager;

    /*//////////////////////////////////////////////////////////////
                            SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public override {
        BaseTest.setUp();

        _gearboxCreditManager = makeAddr("gearbox_credit_manager");

        _fabricOwner = makeAddr("fabric_owner");
        _accountOwners = new address[](1);
        _accountOwners[0] = makeAddr("owner_0");

        // Safe Contracts
        safeProxyFactory = new SafeProxyFactory();
        safeSingleton = new Safe();
        multiSendCallOnly = new MultiSendCallOnly();
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

    function test_deployCreditAccount() public {
        uint256 threshold = 1;

        address safeCreditAccountModule = safeCreditAccountFactory.SAFE_CREDIT_ACCOUNT_MODULE();

        bytes32 salt = keccak256(abi.encodePacked(_accountOwners, threshold));
        address predictedSafeAddress = safeCreditAccountFactory.predictCreditAccountAddress(salt);

        vm.expectEmit(true, true, true, true);
        emit GuardManager.ChangedGuard(safeCreditAccountModule);

        address creditAccount =
            safeCreditAccountFactory.deployCreditAccount(_accountOwners, threshold);

        assertEq(predictedSafeAddress, creditAccount);

        Safe safe = Safe(payable(creditAccount));
        (address[] memory modules,) = safe.getModulesPaginated(SENTINEL_MODULES, 100);
        assertEq(modules.length, 1);
        assertEq(modules[0], safeCreditAccountModule);
    }
}
