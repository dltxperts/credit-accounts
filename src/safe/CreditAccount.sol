pragma solidity ^0.8.24;

import { SafeCreditAccountFallback } from "./CreditAccountFallback.sol";
import { SafeCreditAccountGuard } from "./CreditAccountGuard.sol";

contract SafeCreditAccount is SafeCreditAccountFallback, SafeCreditAccountGuard {
    constructor(
        address _creditManager,
        address _multiSendCallOnly
    )
        SafeCreditAccountFallback(_creditManager)
        SafeCreditAccountGuard(_multiSendCallOnly)
    { }
}
