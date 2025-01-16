pragma solidity ^0.8.24;

import { SafeCreditAccountFallback } from "./SafeCreditAccountFallback.sol";
import { SafeCreditAccountGuard } from "./SafeCreditAccountGuard.sol";

contract SafeCreditAccount is SafeCreditAccountFallback, SafeCreditAccountGuard {
    constructor(address _creditManager) SafeCreditAccountFallback(_creditManager) { }
}
