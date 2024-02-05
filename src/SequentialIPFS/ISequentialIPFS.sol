// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
