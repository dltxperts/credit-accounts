// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { IAddressProvider } from
    "@gearbox-protocol/core-v3/contracts/interfaces/base/IAddressProvider.sol";

contract MockAddressProvider is IAddressProvider {
    mapping(bytes32 => address) internal _addressMap;

    function getAddressOrRevert(
        bytes32 key,
        uint256 version
    )
        external
        view
        override
        returns (address)
    {
        return _addressMap[key];
    }

    // mock for testing
    function setAddress(bytes32 key, address value) external {
        _addressMap[key] = value;
    }
}
