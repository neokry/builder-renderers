// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { BaseMetadata } from "../../../src/BaseMetadata.sol";

contract MockMetadata is BaseMetadata {
    function initialize(bytes calldata _initStrings, address _token) external override initializer {
        // Decode the token initialization strings
        (, , string memory _description, string memory _contractImage, string memory _projectURI, ) = abi.decode(
            _initStrings,
            (string, string, string, string, string, string)
        );

        __BaseMetadata_init(_token, _projectURI, _description, _contractImage);
    }

    function onMinted(uint256) external pure override returns (bool) {
        return true;
    }

    function tokenURI(uint256) external pure override returns (string memory) {
        return "";
    }
}
