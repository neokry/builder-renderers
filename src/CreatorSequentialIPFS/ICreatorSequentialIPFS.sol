// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ICreatorSequentialIPFS
/// @author Neokry
/// @notice The external functions and errors for the creator sequential IPFS metadata renderer
/// @custom:repo github.com/neokry/builder-renderers
interface ICreatorSequentialIPFS {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the creator is set
    /// @param creator The creator address
    event CreatorSet(address creator);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the caller is not the creator
    error ONLY_CREATOR();

    /// @dev Reverts if the array lengths do not match
    error ARRAY_LENGTH_MISMATCH();

    ///                                                          ///
    ///                            FUNCTIONS                     ///
    ///                                                          ///

    /// @notice Sets a metadata item at a specific index
    /// @param _imageURI The metadata image URI
    /// @param _contentURI The metadata content URI
    function setMetadataItem(uint256 _index, string calldata _imageURI, string calldata _contentURI) external;

    /// @notice Sets many metadata items at specific indexes
    /// @param _indexes The indexes to use
    /// @param _imageURIs The metadata image URIs
    /// @param _contentURIs The metadata content URIs
    function setManyMetadataItems(uint256[] calldata _indexes, string[] calldata _imageURIs, string[] calldata _contentURIs) external;

    /// @notice Deletes a metadata item at a specific index
    /// @param _index The index to use
    function deleteMetadataItem(uint256 _index) external;

    /// @notice Sets the fallback metadata item
    /// @param _imageURI The metadata image URI
    /// @param _contentURI The metadata content URI
    function setFallbackMetadataItem(string calldata _imageURI, string calldata _contentURI) external;

    /// @notice sets the creator
    /// @param _newCreator The new creator address
    function setCreator(address _newCreator) external;
}
