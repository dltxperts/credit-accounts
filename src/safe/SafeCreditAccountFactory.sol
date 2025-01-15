pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Gearbox
import {IAccountFactory} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IAccountFactory.sol";
import {NotImplementedException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

// Safe
import {SafeProxyFactory} from "@safe-global/safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import {SafeCreditAccountGuard} from "./SafeCreditAccountGuard.sol";

contract SafeCreditAccountFactory is Ownable, IAccountFactory {
    SafeProxyFactory public immutable SAFE_PROXY_FACTORY;
    address public immutable SAFE_SINGLETON;
    address public immutable SAFE_CREDIT_ACCOUNT_GUARD;

    constructor(address _owner, address _safeProxyFactory, address _safeSingleton) Ownable(_owner) {
        SAFE_PROXY_FACTORY = SafeProxyFactory(_safeProxyFactory);
        SAFE_SINGLETON = _safeSingleton;
        SAFE_CREDIT_ACCOUNT_GUARD = address(new SafeCreditAccountGuard());
    }

    function takeCreditAccount(uint256, uint256) external returns (address creditAccount) {
        return address(0);
    }

    function returnCreditAccount(address) external {
        revert NotImplementedException();
    }

    function addCreditManager(address creditManager) external {
        revert("Not implemented");
    }

    function _deploySafeCreditAccount() internal returns (address) {
        address safeCreditAccount = SAFE_PROXY_FACTORY.createProxyWithNonce(SAFE_SINGLETON, "", 0);
        // ISafe(safeCreditAccount).setup()
        // enableModule()
        // fallback handler
        // setupGuard()
    }
}
