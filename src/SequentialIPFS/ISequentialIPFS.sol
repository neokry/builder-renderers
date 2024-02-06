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
    }

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an implementation is an invalid upgrade
    /// @param impl The address of the invalid implementation
    error INVALID_UPGRADE(address impl);
}
