// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMerklePropertyIPFS {
    ///                                                          ///
    ///                          STRUCTS                         ///
    ///                                                          ///

    struct SetAttributeParams {
        uint256 tokenId;
        uint16[16] attributes;
        bytes32[] proof;
    }

    ///                                                          ///
    ///                          ERRORs                          ///
    ///                                                          ///

    /// @notice Invalid merkle proof
    error INVALID_MERKLE_PROOF(uint256, bytes32[], bytes32);

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @notice Gets the attribute merkle root
    /// @return root The attribute merkle root
    function attributeMerkleRoot() external view returns (bytes32 root);

    /// @notice Sets the attribute merkle root
    /// @param attributeMerkleRoot_ The new attribute merkle root
    function setAttributeMerkleRoot(bytes32 attributeMerkleRoot_) external;

    /// @notice Sets the attributes for a token
    /// @param _params The parameters to use
    function setAttributes(SetAttributeParams calldata _params) external;

    /// @notice Sets the attributes for many tokens
    /// @param _params The parameters to use
    function setManyAttributes(SetAttributeParams[] calldata _params) external;
}
