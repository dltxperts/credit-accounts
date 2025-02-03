// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { ICreditManagerV3 } from
    "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import { ICreditFacadeHooks } from "../../src/interfaces/ICreditFacadeHooks.sol";

contract MockCreditFacadeHooks is ICreditFacadeHooks {
    function preExecutionCheck() external override { }
    function postExecutionCheck() external override { }

    function getOpenCreditAccountContextOrRevert() external view returns (address) {
        return address(0);
    }
}

contract MockCreditManager {
    address public immutable creditFacade;

    constructor() {
        creditFacade = address(new MockCreditFacadeHooks());
    }
}
