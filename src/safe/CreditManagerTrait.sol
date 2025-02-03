// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { ICreditManagerV3 } from
    "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import { CallerNotCreditManagerException } from
    "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

contract CreditManagerTrait {
    address private immutable _creditManager;

    constructor(address creditManager) {
        _creditManager = creditManager;
    }

    function _getCreditFacade() internal view returns (address) {
        return ICreditManagerV3(_creditManager).creditFacade();
    }

    function _getCreditManager() internal view returns (address) {
        return _creditManager;
    }

    function _revertIfNotCreditManager(address msgSender) internal view {
        if (msgSender != _creditManager) {
            revert CallerNotCreditManagerException();
        }
    }
}
