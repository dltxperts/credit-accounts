// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

library Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface ISafe {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    )
        external;

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    )
        external
        returns (bool success);

    /**
     * @dev Allows a Module to execute a Safe transaction without any further confirmations.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     */
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    )
        external
        returns (bool success);

    /**
     * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token)
     * and return data
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     * @return returnData Data returned by the call.
     */
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    )
        external
        returns (bool success, bytes memory returnData);

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will
     * revert
     * otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified. Can be ECDSA signature, contract
     * signature (EIP-1271) or approved hash.
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    )
        external
        view;

    function signedMessages(bytes32) external view returns (uint256);

    /**
     * @dev Returns the domain separator for this contract, as defined in the EIP-712 standard.
     * @return bytes32 The domain separator hash.
     */
    function domainSeparator() external view returns (bytes32);

    function VERSION() external pure returns (string memory);

    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);

    /**
     * @dev Returns array of modules.
     * @param start Start of the page.
     * @param pageSize Maximum number of modules that should be returned.
     * @return array Array of modules.
     * @return next Start of the next page.
     */
    function getModulesPaginated(
        address start,
        uint256 pageSize
    )
        external
        view
        returns (address[] memory array, address next);

    /**
     * @notice Enables the module `module` for the Safe.
     * @dev This can only be done via a Safe transaction.
     * @param module Module to be enabled.
     */
    function enableModule(address module) external;

    function disableModule(address module) external;

    function setModuleGuard(address moduleGuard) external;

    function setGuard(address guard) external;

    function getGuard() external view returns (address);

    function setFallbackHandler(address handler) external;

    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external;

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        external
        view
        returns (bytes32);
}
