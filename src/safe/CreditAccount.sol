pragma solidity ^0.8.24;

import { SafeCreditAccountFallback } from "./CreditAccountFallback.sol";
import { SafeCreditAccountGuard } from "./CreditAccountGuard.sol";
import { CreditManagerTrait } from "./CreditManagerTrait.sol";

contract SafeCreditAccount is SafeCreditAccountFallback, SafeCreditAccountGuard {
    constructor(
        address _creditManager,
        address _multiSendCallOnly
    )
        CreditManagerTrait(_creditManager)
        SafeCreditAccountFallback()
        SafeCreditAccountGuard(_multiSendCallOnly)
    { }
}
