pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Gearbox
import { IAccountFactory } from
    "@gearbox-protocol/core-v3/contracts/interfaces/base/IAccountFactory.sol";
import { NotImplementedException } from
    "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

// Safe
import { ISafe, Enum } from "./interfaces/ISafe.sol";
import { MultiSendCallOnly } from
    "@safe-global/safe-contracts/contracts/libraries/MultiSendCallOnly.sol";
import { SafeProxyFactory } from
    "@safe-global/safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import { SafeCreditAccount } from "./SafeCreditAccount.sol";

contract SafeCreditAccountFactory is Ownable, IAccountFactory {
    SafeProxyFactory public immutable SAFE_PROXY_FACTORY;
    address public immutable SAFE_SINGLETON;
    address public immutable SAFE_CREDIT_ACCOUNT_MODULE;
    address public immutable MULTI_SEND_CALL_ONLY;

    /// @notice Contract type
    bytes32 public constant override contractType = "ACCOUNT_FACTORY::SAFE";

    /// @notice Contract version
    uint256 public constant override version = 3_20;

    constructor(
        address _owner,
        address _safeProxyFactory,
        address _safeSingleton,
        address _multiSendCallOnly,
        address _gearboxCreditManager
    ) {
        SAFE_PROXY_FACTORY = SafeProxyFactory(_safeProxyFactory);
        SAFE_SINGLETON = _safeSingleton;
        SAFE_CREDIT_ACCOUNT_MODULE = address(new SafeCreditAccount(_gearboxCreditManager));
        MULTI_SEND_CALL_ONLY = _multiSendCallOnly;
        transferOwnership(_owner);
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

    function deployCreditAccount(
        address[] memory owners,
        uint256 threshold
    )
        external
        returns (address)
    {
        return _deploySafeCreditAccount(owners, threshold);
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
        address[] memory owners,
        uint256 threshold
    )
        internal
        returns (address)
    {
        uint256 salt = uint256(keccak256(abi.encodePacked(owners, threshold)));
        address safeCreditAccount =
            address(SAFE_PROXY_FACTORY.createProxyWithNonce(SAFE_SINGLETON, "", salt));

        bytes memory enableModuleData = _encodeOperation(
            safeCreditAccount, abi.encodeCall(ISafe.enableModule, (SAFE_CREDIT_ACCOUNT_MODULE))
        );
        bytes memory setGuardData = _encodeOperation(
            safeCreditAccount, abi.encodeCall(ISafe.setGuard, (SAFE_CREDIT_ACCOUNT_MODULE))
        );

        bytes memory multiSendData = abi.encodePacked(enableModuleData, setGuardData);
        bytes memory multiSendCall = abi.encodeCall(MultiSendCallOnly.multiSend, (multiSendData));

        ISafe(safeCreditAccount).setup(
            owners,
            threshold,
            MULTI_SEND_CALL_ONLY,
            multiSendCall,
            SAFE_CREDIT_ACCOUNT_MODULE,
            address(0),
            0,
            payable(address(0))
        );

        return safeCreditAccount;
    }

    /// @dev Encodes an operation for MultiSendCallOnly contract
    function _encodeOperation(
        address target,
        bytes memory callData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            uint8(Enum.Operation.Call), target, uint256(0), uint256(callData.length), callData
        );
    }
}
