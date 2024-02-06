// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { UUPSUpgradeable } from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { MetadataBuilder } from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import { MetadataJSONKeys } from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";
import { UriEncode } from "sol-uriencode/src/UriEncode.sol";

import { IManager } from "../lib/interfaces/IManager.sol";
import { ISequentialIPFS } from "./ISequentialIPFS.sol";
import { BaseMetadata } from "../BaseMetadata.sol";

/// @title Sequential IPFS Metadata Renderer
/// @author Neokry
/// @notice A metadata renderer that uses a list of IPFS URIs for the token metadata
/// @custom:repo github.com/neokry/builder-renderers
abstract contract SequentialIPFS is ISequentialIPFS, BaseMetadata, UUPSUpgradeable {
    ///                                                          ///
    ///                          STRUCTS                         ///
    ///                                                          ///

    /// @custom:storage-location erc7201:nounsbuilder.storage.SequentialIPFSRenderer
    struct SequentialIPFSStorage {
        MetadataItem _fallbackMetadataItem;
        mapping(uint256 index => MetadataItem item) _metadataItems;
    }

    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    // keccak256(abi.encode(uint256(keccak256("nounsbuilder.storage.SequentialIPFSRenderer")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SequentialIPFSStorageLocation = 0x05c4f2ac24bde1c6d3668207bfbaacf34d42aefcc22fb39b8e3b0412e188dd00;

    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @notice The contract upgrade manager
    address private immutable manager;

    ///                                                          ///
    ///                          STORAGE                         ///
    ///                                                          ///

    function _getSequentialIPFSStorage() private pure returns (SequentialIPFSStorage storage $) {
        assembly {
            $.slot := SequentialIPFSStorageLocation
        }
    }

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _manager The contract upgrade manager address
    constructor(address _manager) payable {
        manager = _manager;
    }

    ///                                                          ///
    ///                          INITILIZER                      ///
    ///                                                          ///

    function initialize(bytes calldata _initStrings, address _token) external override initializer {
        // Ensure the caller is the contract manager
        if (msg.sender != address(manager)) {
            revert ONLY_MANAGER();
        }

        // Decode the token initialization strings
        (, , string memory _description, string memory _contractImage, string memory _projectURI, ) = abi.decode(
            _initStrings,
            (string, string, string, string, string, string)
        );

        __BaseMetadata_init(_token, _projectURI, _description, _contractImage);
    }

    ///                                                          ///
    ///                        METADATA ITEMS                    ///
    ///                                                          ///

    /// @notice Get a metadata item at a specific index
    /// @param _index The index to use
    /// @return The metadata item
    function getMetadataItem(uint256 _index) external view returns (MetadataItem memory) {
        SequentialIPFSStorage storage $ = _getSequentialIPFSStorage();
        return $._metadataItems[_index];
    }

    /// @notice Get the current fallback metadata item
    /// @return The fallback metadata item
    function getFallbackMetadataItem() external view returns (MetadataItem memory) {
        SequentialIPFSStorage storage $ = _getSequentialIPFSStorage();
        return $._fallbackMetadataItem;
    }

    /// @notice Delete a metadata item at a specific index
    /// @param _index The index to use
    function _deleteMetadataItem(uint256 _index) internal {
        SequentialIPFSStorage storage $ = _getSequentialIPFSStorage();
        delete $._metadataItems[_index];
    }

    /// @notice Set a metadata item at a specific index
    /// @param _index The index to use
    /// @param _imageURI The metadata image URI
    /// @param _contentURI The metadata content URI
    function _setMetadataItem(uint256 _index, string calldata _imageURI, string calldata _contentURI) internal {
        SequentialIPFSStorage storage $ = _getSequentialIPFSStorage();
        MetadataItem storage item = $._metadataItems[_index];
        item.imageURI = _imageURI;
        item.contentURI = _contentURI;

        if (!item.active) {
            item.active = true;
        }
    }

    /// @notice Sets the fallback metadata item
    /// @param _imageURI The metadata image URI
    /// @param _contentURI The metadata content URI
    function _setFallbackMetadataItem(string calldata _imageURI, string calldata _contentURI) internal {
        SequentialIPFSStorage storage $ = _getSequentialIPFSStorage();
        $._fallbackMetadataItem.imageURI = _imageURI;
        $._fallbackMetadataItem.contentURI = _contentURI;
    }

    function _getTokenMetadataOrFallback(uint256 _tokenId) internal view returns (MetadataItem memory) {
        SequentialIPFSStorage storage $ = _getSequentialIPFSStorage();
        MetadataItem memory item = $._metadataItems[_tokenId];
        return item.active ? item : $._fallbackMetadataItem;
    }

    ///                                                          ///
    ///                     ATTRIBUTE GENERATION                 ///
    ///                                                          ///

    /// @notice Callback for when a token is minted
    function onMinted(uint256) external pure override returns (bool) {
        return true;
    }

    ///                                                          ///
    ///                            URIs                          ///
    ///                                                          ///

    /// @notice Get the token URI
    /// @param _tokenId The token ID
    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        AdditionalTokenProperty[] memory additionalTokenProperties = getAdditionalTokenProperties();
        MetadataItem memory tokenMetadataItem = _getTokenMetadataOrFallback(_tokenId);

        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](4 + additionalTokenProperties.length);

        items[0] = MetadataBuilder.JSONItem({
            key: MetadataJSONKeys.keyName,
            value: string.concat(_name(), " #", Strings.toString(_tokenId)),
            quote: true
        });
        items[1] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyDescription, value: description(), quote: true });
        items[2] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyImage, value: tokenMetadataItem.imageURI, quote: true });

        // keccak256(abi.encode(tokenMetadataItem.contentURI)) != keccak256("")
        bool hasContentURI = keccak256(abi.encode(tokenMetadataItem.contentURI)) !=
            bytes32(0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);

        // Add the content URI if it exists
        if (hasContentURI) {
            items[3] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyAnimationURL, value: tokenMetadataItem.contentURI, quote: true });
        }

        uint256 baseIndex = hasContentURI ? 4 : 3;
        for (uint256 i = 0; i < additionalTokenProperties.length; i++) {
            AdditionalTokenProperty memory tokenProperties = additionalTokenProperties[i];
            items[baseIndex + i] = MetadataBuilder.JSONItem({ key: tokenProperties.key, value: tokenProperties.value, quote: tokenProperties.quote });
        }

        return MetadataBuilder.generateEncodedJSON(items);
    }

    ///                                                          ///
    ///                        METADATA UPGRADE                  ///
    ///                                                          ///

    function _authorizeUpgrade(address _impl) internal virtual override onlyOwner {
        if (!IManager(manager).isRegisteredUpgrade(ERC1967Utils.getImplementation(), _impl)) revert INVALID_UPGRADE(_impl);
    }
}
