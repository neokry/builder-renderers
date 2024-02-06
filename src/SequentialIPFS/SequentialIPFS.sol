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

contract SequentialIPFS is ISequentialIPFS, BaseMetadata, UUPSUpgradeable {
    ///                                                          ///
    ///                          STRUCTS                         ///
    ///                                                          ///

    /// @custom:storage-location erc7201:nounsbuilder.storage.SequentialIPFSRenderer
    struct SequentialIPFSStorage {
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

    function onMinted(uint256) external pure override returns (bool) {
        return true;
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        SequentialIPFSStorage memory $ = _getSequentialIPFSStorage();
        AdditionalTokenProperty[] memory additionalTokenProperties = getAdditionalTokenProperties();

        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](4 + additionalTokenProperties.length);

        items[0] = MetadataBuilder.JSONItem({
            key: MetadataJSONKeys.keyName,
            value: string.concat(_name(), " #", Strings.toString(_tokenId)),
            quote: true
        });
        items[1] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyDescription, value: description(), quote: true });
        items[2] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyImage, value: $._metadataItems[_tokenId].imageURI, quote: true });
        items[3] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyAnimationURL, value: $._metadataItems[_tokenId].contentURI, quote: false });

        for (uint256 i = 0; i < additionalTokenProperties.length; i++) {
            AdditionalTokenProperty memory tokenProperties = additionalTokenProperties[i];
            items[4 + i] = MetadataBuilder.JSONItem({ key: tokenProperties.key, value: tokenProperties.value, quote: tokenProperties.quote });
        }

        return MetadataBuilder.generateEncodedJSON(items);
    }

    function _authorizeUpgrade(address _impl) internal virtual override onlyOwner {
        if (!IManager(manager).isRegisteredUpgrade(ERC1967Utils.getImplementation(), _impl)) revert INVALID_UPGRADE(_impl);
    }
}
