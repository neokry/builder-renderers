// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts/access/Ownable2StepUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { MetadataBuilder } from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import { MetadataJSONKeys } from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";
import { IBaseMetadata } from "./IBaseMetadata.sol";

abstract contract BaseMetadata is IBaseMetadata, Initializable, Ownable2StepUpgradeable {
    /// @custom:storage-location erc7201:nounsbuilder.storage.BaseMetadata
    struct BaseMetadataStorage {
        address _token;
        string _projectURI;
        string _description;
        string _contractImage;
        AdditionalTokenProperty[] _additionalTokenProperties;
    }

    // keccak256(abi.encode(uint256(keccak256("nounsbuilder.storage.BaseMetadata")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BaseMetadataStorageLocation = 0x80bb2b638cc20bc4d0a60d66940f3ab4a00c1d7b313497ca82fb0b4ab0079300;

    function _getBaseMetadataStorage() private pure returns (BaseMetadataStorage storage $) {
        assembly {
            $.slot := BaseMetadataStorageLocation
        }
    }

    function __BaseMetadata_init(
        address token_,
        string memory projectURI_,
        string memory description_,
        string memory contractImage_
    ) internal onlyInitializing {
        BaseMetadataStorage storage $ = _getBaseMetadataStorage();

        $._token = token_;
        $._projectURI = projectURI_;
        $._description = description_;
        $._contractImage = contractImage_;
    }

    /// @notice Updates the additional token properties associated with the metadata.
    /// @dev Be careful to not conflict with already used keys such as "name", "description", "properties",
    function setAdditionalTokenProperties(AdditionalTokenProperty[] memory _additionalTokenProperties) external onlyOwner {
        BaseMetadataStorage storage $ = _getBaseMetadataStorage();

        delete $._additionalTokenProperties;
        for (uint256 i = 0; i < _additionalTokenProperties.length; i++) {
            $._additionalTokenProperties.push(_additionalTokenProperties[i]);
        }

        emit AdditionalTokenPropertiesSet(_additionalTokenProperties);
    }

    /// @notice The properties and query string for a generated token
    /// @param _tokenId The ERC-721 token id
    function getAttributes(uint256 _tokenId) public view returns (string memory resultAttributes, string memory queryString) {
        BaseMetadataStorage storage $ = _getBaseMetadataStorage();

        // Get the token's query string
        queryString = string.concat(
            "?contractAddress=",
            Strings.toHexString(uint256(uint160(address(this))), 20),
            "&tokenId=",
            Strings.toString(_tokenId)
        );

        // Get the token's generated attributes
        uint16[16] memory tokenAttributes = $._attributes[_tokenId];

        // Cache the number of properties when the token was minted
        uint256 numProperties = tokenAttributes[0];

        // Ensure the given token was minted
        if (numProperties == 0) revert TOKEN_NOT_MINTED(_tokenId);

        // Get an array to store the token's generated attribtues
        MetadataBuilder.JSONItem[] memory arrayAttributesItems = new MetadataBuilder.JSONItem[](numProperties);

        unchecked {
            // For each of the token's properties:
            for (uint256 i = 0; i < numProperties; ++i) {
                // Get its name and list of associated items
                Property memory property = properties[i];

                // Get the randomly generated index of the item to select for this token
                uint256 attribute = tokenAttributes[i + 1];

                // Get the associated item data
                Item memory item = property.items[attribute];

                // Store the encoded attributes and query string
                MetadataBuilder.JSONItem memory itemJSON = arrayAttributesItems[i];

                itemJSON.key = property.name;
                itemJSON.value = item.name;
                itemJSON.quote = true;

                queryString = string.concat(queryString, "&images=", _getItemImage(item, property.name));
            }

            resultAttributes = MetadataBuilder.generateJSON(arrayAttributesItems);
        }
    }
}
