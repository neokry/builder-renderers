// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICreatorSequentialIPFS } from "./ICreatorSequentialIPFS.sol";
import { SequentialIPFS } from "../SequentialIPFS/SequentialIPFS.sol";
import { IToken } from "../lib/interfaces/IToken.sol";

/// @title Creator Sequential IPFS Metadata Renderer
/// @author Neokry
/// @notice A property metadata renderer that allows a creator to set metadata items
/// @custom:repo github.com/neokry/builder-renderers
contract CreatorSequentialIPFS is ICreatorSequentialIPFS, SequentialIPFS {
    ///                                                          ///
    ///                          STRUCTS                         ///
    ///                                                          ///

    /// @custom:storage-location erc7201:nounsbuilder.storage.CreatorSequentialIPFSRenderer
    struct CreatorSequentialIPFSStorage {
        address _creator;
    }

    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    // keccak256(abi.encode(uint256(keccak256("nounsbuilder.storage.CreatorSequentialIPFSRenderer")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CreatorSequentialIPFSStorageLocation = 0x7a7efe8a736f8bd5222edf9aead5216866fcf60ec6cb41906185ddc46f703d00;

    ///                                                          ///
    ///                          MODIFIERS                       ///
    ///                                                          ///

    modifier onlyCreator() {
        if (msg.sender != _creator()) {
            revert ONLY_CREATOR();
        }

        _;
    }

    ///                                                          ///
    ///                          STORAGE                         ///
    ///                                                          ///

    function _getCreatorSequentialIPFSStorage() private pure returns (CreatorSequentialIPFSStorage storage $) {
        assembly {
            $.slot := CreatorSequentialIPFSStorageLocation
        }
    }

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _manager The contract upgrade manager address
    constructor(address _manager) SequentialIPFS(_manager) {}

    ///                                                          ///
    ///                        METADATA ITEMS                    ///
    ///                                                          ///

    /// @notice Sets a metadata item at a specific index
    /// @param _imageURI The metadata image URI
    /// @param _contentURI The metadata content URI
    function setMetadataItem(uint256 _index, string calldata _imageURI, string calldata _contentURI) external onlyCreator {
        _setMetadataItem(_index, _imageURI, _contentURI);

        emit MetadataUpdate(_index);
    }

    /// @notice Sets a metadata item at a specific index
    /// @param _imageURI The metadata image URI
    function setMetadataImageURI(uint256 _index, string calldata _imageURI) external onlyCreator {
        _setMetadataItem(_index, _imageURI, "");

        emit MetadataUpdate(_index);
    }

    /// @notice Sets many metadata items at specific indexes
    /// @param _indexes The indexes to use
    /// @param _imageURIs The metadata image URIs
    /// @param _contentURIs The metadata content URIs
    function setManyMetadataItems(uint256[] calldata _indexes, string[] calldata _imageURIs, string[] calldata _contentURIs) external onlyCreator {
        uint256 length = _indexes.length;

        if (length != _imageURIs.length || length != _contentURIs.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        unchecked {
            for (uint256 i; i < length; ++i) {
                _setMetadataItem(_indexes[i], _imageURIs[i], _contentURIs[i]);
                emit MetadataUpdate(i);
            }
        }
    }

    /// @notice Deletes a metadata item at a specific index
    /// @param _index The index to use
    function deleteMetadataItem(uint256 _index) external onlyCreator {
        _deleteMetadataItem(_index);

        emit MetadataUpdate(_index);
    }

    /// @notice Sets the fallback metadata item
    /// @param _imageURI The metadata image URI
    /// @param _contentURI The metadata content URI
    function setFallbackMetadataItem(string calldata _imageURI, string calldata _contentURI) external onlyCreator {
        _setFallbackMetadataItem(_imageURI, _contentURI);

        uint256 totalSupply = IToken(token()).totalSupply();

        if (totalSupply > 0) {
            emit BatchMetadataUpdate(0, IToken(token()).totalSupply() - 1);
        }
    }

    /// @notice Sets the fallback metadata item
    /// @param _imageURI The metadata image URI
    function setFallbackMetadataImageURI(string calldata _imageURI) external onlyCreator {
        _setFallbackMetadataItem(_imageURI, "");

        uint256 totalSupply = IToken(token()).totalSupply();

        if (totalSupply > 0) {
            emit BatchMetadataUpdate(0, IToken(token()).totalSupply() - 1);
        }
    }

    /// @notice sets the creator
    /// @param _newCreator The new creator address
    function setCreator(address _newCreator) external onlyOwner {
        _setCreator(_newCreator);

        emit CreatorSet(_newCreator);
    }

    function getCreator() external pure returns (address) {
        return _creator();
    }

    function _creator() internal pure returns (address creator) {
        CreatorSequentialIPFSStorage memory $ = _getCreatorSequentialIPFSStorage();
        creator = $._creator;
    }

    function _setCreator(address _newCreator) internal {
        CreatorSequentialIPFSStorage storage $ = _getCreatorSequentialIPFSStorage();
        $._creator = _newCreator;
    }

    ///                                                          ///
    ///                        SUPPORTS INTERFACE                ///
    ///                                                          ///

    /// @notice If the contract implements an interface
    /// @param _interfaceId The interface id
    function supportsInterface(bytes4 _interfaceId) public pure override returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == type(ICreatorSequentialIPFS).interfaceId;
    }
}
