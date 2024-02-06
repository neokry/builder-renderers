// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IPropertyIPFS
/// @author Neokry
/// @notice The external functions and errors for the sequential IPFS metadata renderer
/// @custom:repo github.com/neokry/builder-renderers
interface ISequentialIPFS {
    ///                                                          ///
    ///                            STRUCTS                       ///
    ///                                                          ///

    struct MetadataItem {
        string imageURI;
        string contentURI;
        bool active;
    }

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an implementation is an invalid upgrade
    /// @param impl The address of the invalid implementation
    error INVALID_UPGRADE(address impl);

    ///                                                          ///
    ///                        FUNCTIONS                         ///
    ///                                                          ///

    /// @notice Get a metadata item at a specific index
    /// @param _index The index to use
    /// @return The metadata item
    function getMetadataItem(uint256 _index) external view returns (MetadataItem memory);

    /// @notice Get the current fallback metadata item
    /// @return The fallback metadata item
    function getFallbackMetadataItem() external view returns (MetadataItem memory);
}
