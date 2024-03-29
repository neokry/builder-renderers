// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract VersionedContract {
    function contractVersion() external pure returns (string memory) {
        return "2.0.0";
    }
}
