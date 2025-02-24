// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { MultiSendLib } from "./libraries/MultiSendLib.sol";
import { Call } from "../DataTypes.sol";

// Gearbox
import { IAccountFactory } from
    "@gearbox-protocol/core-v3/contracts/interfaces/base/IAccountFactory.sol";
import { ICreditManagerV3 } from
    "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {
    NotImplementedException,
    CallerNotCreditManagerException,
    MasterCreditAccountAlreadyDeployedException
} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";
import { IAddressProvider } from
    "@gearbox-protocol/core-v3/contracts/interfaces/base/IAddressProvider.sol";
import {
    AP_INSTANCE_MANAGER_PROXY,
    NO_VERSION_CONTROL
} from "@gearbox-protocol/core-v3/contracts/libraries/Constants.sol";

import { ICreditFacadeHooks } from "../interfaces/ICreditFacadeHooks.sol";

// Safe
import { ISafe } from "./interfaces/ISafe.sol";
import { MultiSendCallOnly } from
    "@safe-global/safe-contracts/contracts/libraries/MultiSendCallOnly.sol";
import { SafeProxyFactory } from
    "@safe-global/safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import { SafeCreditAccount } from "./CreditAccount.sol";

contract SafeCreditAccountFactory is Ownable, IAccountFactory {
    SafeProxyFactory public immutable SAFE_PROXY_FACTORY;
    address public immutable SAFE_SINGLETON;
    // address public immutable SAFE_CREDIT_ACCOUNT_MODULE;
    address public immutable MULTI_SEND_CALL_ONLY;

    /// @notice Contract type
    bytes32 public constant override contractType = "ACCOUNT_FACTORY::SAFE";

    /// @notice Contract version
    uint256 public constant override version = 3_20;

    /// @notice Mapping credit manager => safe accoutn module
    mapping(address => address) internal _creditManagerToSafeAccountModule;

    constructor(
        address _addressProvider,
        address _safeProxyFactory,
        address _safeSingleton,
        address _multiSendCallOnly
    ) {
        SAFE_PROXY_FACTORY = SafeProxyFactory(_safeProxyFactory);
        SAFE_SINGLETON = _safeSingleton;
        MULTI_SEND_CALL_ONLY = _multiSendCallOnly;
        transferOwnership(
            IAddressProvider(_addressProvider).getAddressOrRevert(
                AP_INSTANCE_MANAGER_PROXY, NO_VERSION_CONTROL
            )
        );
    }

    function takeCreditAccount(uint256, uint256) external returns (address creditAccount) {
        address creditAccountModule = _creditManagerToSafeAccountModule[msg.sender];
        if (creditAccountModule == address(0)) {
            revert CallerNotCreditManagerException();
        }

        address creditFacade = ICreditManagerV3(msg.sender).creditFacade();
        address owner = ICreditFacadeHooks(creditFacade).getOpenCreditAccountContextOrRevert();

        address[] memory owners = new address[](1);
        owners[0] = owner;
        creditAccount = _deploySafeCreditAccount(creditAccountModule, owners, 1);
    }

    function returnCreditAccount(address) external {
        revert NotImplementedException();
    }

    function addCreditManager(address creditManager) external {
        if (_creditManagerToSafeAccountModule[creditManager] != address(0)) {
            revert MasterCreditAccountAlreadyDeployedException();
        }

        address creditAccountModule =
            address(new SafeCreditAccount(creditManager, MULTI_SEND_CALL_ONLY));
        _creditManagerToSafeAccountModule[creditManager] = creditAccountModule;
    }

    function predictCreditAccountAddress(bytes32 salt) external view returns (address safeProxy) {
        salt = keccak256(abi.encodePacked(keccak256(""), salt));

        bytes memory creationCode = SAFE_PROXY_FACTORY.proxyCreationCode();

        safeProxy = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(SAFE_PROXY_FACTORY),
                            salt,
                            keccak256(
                                abi.encodePacked(
                                    creationCode, uint256(uint160(address(SAFE_SINGLETON)))
                                )
                            )
                        )
                    )
                )
            )
        );

        return safeProxy;
    }

    function _deploySafeCreditAccount(
        address creditAccountModule,
        address[] memory owners,
        uint256 threshold
    )
        internal
        returns (address)
    {
        uint256 salt = uint256(keccak256(abi.encodePacked(owners, threshold)));
        address safeCreditAccount =
            address(SAFE_PROXY_FACTORY.createProxyWithNonce(SAFE_SINGLETON, "", salt));

        Call[] memory calls = new Call[](2);
        calls[0] =
            Call(safeCreditAccount, 0, abi.encodeCall(ISafe.enableModule, (creditAccountModule)));
        calls[1] = Call(safeCreditAccount, 0, abi.encodeCall(ISafe.setGuard, (creditAccountModule)));

        bytes memory multiSendData = MultiSendLib.encodeMultisendCallOnly(calls);
        bytes memory multiSendCall = abi.encodeCall(MultiSendCallOnly.multiSend, (multiSendData));

        ISafe(safeCreditAccount).setup(
            owners,
            threshold,
            MULTI_SEND_CALL_ONLY,
            multiSendCall,
            creditAccountModule,
            address(0),
            0,
            payable(address(0))
        );

        return safeCreditAccount;
    }

    function serialize() external view returns (bytes memory) {
        return "";
    }
}
