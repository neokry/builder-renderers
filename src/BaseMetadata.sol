// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

abstract contract BaseMetadata {
    struct AdditionalTokenProperty {
        string key;
        string value;
        bool quote;
    }

    /// @custom:storage-location erc7201:nounsbuilder.storage.BaseMetadata
    struct BaseMetadataStorage {
        address token;
        string projectURI;
        string description;
        string contractImage;
        AdditionalTokenProperty[] additionalTokenProperties;
    }

    // keccak256(abi.encode(uint256(keccak256("nounsbuilder.storage.BaseMetadata")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BaseMetadataStorageLocation = 0x80bb2b638cc20bc4d0a60d66940f3ab4a00c1d7b313497ca82fb0b4ab0079300;

    function _getBaseMetadataStorage() private pure returns (BaseMetadataStorage storage $) {
        assembly {
            $.slot := BaseMetadataStorageLocation
        }
    }

    function __BaseMetadata_init(string memory name_, string memory symbol_) internal {}

    constructor() {}
}
