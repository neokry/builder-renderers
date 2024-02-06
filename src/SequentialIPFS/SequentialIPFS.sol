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
        MetadataItem[] _metadataItems;
    }

    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    // keccak256(abi.encode(uint256(keccak256("nounsbuilder.storage.SequentialIPFSRenderer")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SequentialIPFSStorageLocation = 0x6e86adc91987cfd0c2727f2061f4e6022e5e9212736e682f4eb1f6949f6a7b00;

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

    /// @notice Get the current metadata items
    /// @return The metadata items
    function getMetadataItems() external pure returns (MetadataItem[] memory) {
        SequentialIPFSStorage memory $ = _getSequentialIPFSStorage();
        return $._metadataItems;
    }

    /// @notice Get the current fallback metadata item
    /// @return The fallback metadata item
    function getFallbackMetadataItem() external pure returns (MetadataItem memory) {
        SequentialIPFSStorage memory $ = _getSequentialIPFSStorage();
        return $._fallbackMetadataItem;
    }

    /// @notice Add a new metadata item
    /// @param _metadataItem The metadata item to add
    function _addMetadataItem(MetadataItem calldata _metadataItem) internal {
        SequentialIPFSStorage storage $ = _getSequentialIPFSStorage();
        $._metadataItems.push(_metadataItem);
    }

    /// @notice Set a metadata item at a specific index
    /// @param _index The index to set the metadata item at
    function _setMetadataItem(uint256 _index, MetadataItem calldata _metadataItem) internal {
        SequentialIPFSStorage storage $ = _getSequentialIPFSStorage();
        $._metadataItems[_index] = _metadataItem;
    }

    /// @notice Sets the fallback metadata item
    /// @param _metadataItem The metadata item to set as the fallback
    function _setFallbackMetadataItem(MetadataItem calldata _metadataItem) internal {
        SequentialIPFSStorage storage $ = _getSequentialIPFSStorage();
        $._fallbackMetadataItem = _metadataItem;
    }

    function _getTokenMetadataOrFallback(uint256 _tokenId) internal pure returns (MetadataItem memory) {
        SequentialIPFSStorage memory $ = _getSequentialIPFSStorage();
        if (_tokenId < $._metadataItems.length) {
            return $._metadataItems[_tokenId];
        }
        return $._fallbackMetadataItem;
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

        bool hasContentURI = keccak256(abi.encode(tokenMetadataItem.contentURI)) != keccak256("");

        // Ignore the content URI if it is empty
        if (hasContentURI) {
            items[3] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyAnimationURL, value: tokenMetadataItem.contentURI, quote: false });
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
