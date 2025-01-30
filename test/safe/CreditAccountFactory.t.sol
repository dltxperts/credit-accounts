pragma solidity ^0.8.24;

// import { BaseTest } from "../Base.t.sol";
import { BaseSafeTest } from "./BaseSafe.t.sol";
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

contract CreditAccountFactoryTest is BaseSafeTest {
    /*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

    address constant SENTINEL_MODULES = address(0x1);

    /*//////////////////////////////////////////////////////////////
                            SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                            TESTS
    //////////////////////////////////////////////////////////////*/

    function test_deployCreditAccount() public {
        uint256 threshold = 1;
        address[] memory accountOwners = new address[](1);
        accountOwners[0] = makeAddr("owner_0");

        address expectedSafeCreditAccountModule =
            safeCreditAccountFactory.getSafeCreditAccountModule(gearboxCreditManager);

        bytes32 salt = keccak256(abi.encodePacked(accountOwners, threshold));
        address predictedSafeAddress = safeCreditAccountFactory.predictCreditAccountAddress(salt);

        vm.expectEmit(true, true, true, true);
        emit GuardManager.ChangedGuard(expectedSafeCreditAccountModule);

        address creditAccount = safeCreditAccountFactory.deployCreditAccount(
            gearboxCreditManager, accountOwners, threshold
        );

        assertEq(predictedSafeAddress, creditAccount);

        Safe safe = Safe(payable(creditAccount));
        (address[] memory modules,) = safe.getModulesPaginated(SENTINEL_MODULES, 100);
        assertEq(modules.length, 1);
        assertEq(modules[0], expectedSafeCreditAccountModule);
    }
}
