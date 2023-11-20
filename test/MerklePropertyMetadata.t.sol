// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { MerklePropertyIPFS, IMerklePropertyIPFS } from "../src/MerklePropertyIPFS/MerklePropertyIPFS.sol";
import { IPropertyIPFS } from "../src/PropertyIPFS/PropertyIPFS.sol";
import { MockToken } from "./utils/mocks/MockToken.sol";
import { PropertyIPFSTest } from "./utils/PropertyIPFSTest.sol";
import { Base64URIDecoder } from "./utils/Base64URIDecoder.sol";

contract MerklePropertyMetadataTest is PropertyIPFSTest {
    MerklePropertyIPFS metadata;
    MockToken token;

    address user;
    address owner;
    address manager;

    function setUp() public {
        user = address(0xA11CE);
        owner = address(0xB0B);
        manager = address(0x4A4A6E6);

        metadata = new MerklePropertyIPFS(manager);
        token = new MockToken(owner);

        setMockInitStrings();

        vm.prank(manager);
        metadata.initialize(initStrings, address(token));
    }

    function test_SetAttributes() external {
        bytes32 root = 0x5e0f333d56d9716c0e2ae5f990981023f2bc6cb23eba6c7d60ba8146af726a8b;

        vm.prank(owner);
        metadata.setAttributeMerkleRoot(root);

        uint16[16] memory attributes;
        attributes[0] = 5;
        attributes[1] = 8;
        attributes[2] = 4;
        attributes[3] = 2;
        attributes[4] = 1;
        attributes[5] = 0;

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0x040ebb2969ff59488f98dc7cd9014aa8b112ba4bf78c2f8bcf03be0fad0d2e0e;

        IMerklePropertyIPFS.SetAttributeParams memory params = IMerklePropertyIPFS.SetAttributeParams({
            tokenId: 1,
            attributes: attributes,
            proof: proof
        });

        metadata.setAttributes(params);

        uint16[16] memory newAttributes = metadata.getRawAttributes(1);
        assertEq(keccak256(abi.encode(newAttributes)), keccak256(abi.encode(attributes)));
    }

    function testRevert_SetAttributesInvalidProof() external {
        bytes32 root = 0x5e0f333d56d9716c0e2ae5f990981023f2bc6cb23eba6c7d60ba8146af726a8b;

        vm.prank(owner);
        metadata.setAttributeMerkleRoot(root);

        uint16[16] memory attributes;
        attributes[0] = 5;
        attributes[1] = 8;
        attributes[2] = 4;
        attributes[3] = 2;
        attributes[4] = 1;
        attributes[5] = 0;

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0x040ebb2969ff59488f98dc7cd9014aa8b112ba4bf78c2f8bcf03be0fad0d2e0f;

        IMerklePropertyIPFS.SetAttributeParams memory params = IMerklePropertyIPFS.SetAttributeParams({
            tokenId: 1,
            attributes: attributes,
            proof: proof
        });

        vm.expectRevert(abi.encodeWithSignature("INVALID_MERKLE_PROOF(uint256,bytes32[],bytes32)", 1, proof, root));
        metadata.setAttributes(params);
    }

    function test_SetAttributesBeforeOnMinted() external {
        bytes32 root = 0x5e0f333d56d9716c0e2ae5f990981023f2bc6cb23eba6c7d60ba8146af726a8b;

        vm.prank(owner);
        metadata.setAttributeMerkleRoot(root);

        uint16[16] memory attributes;
        attributes[0] = 5;
        attributes[1] = 8;
        attributes[2] = 4;
        attributes[3] = 2;
        attributes[4] = 1;
        attributes[5] = 0;

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0x040ebb2969ff59488f98dc7cd9014aa8b112ba4bf78c2f8bcf03be0fad0d2e0e;

        IMerklePropertyIPFS.SetAttributeParams memory params = IMerklePropertyIPFS.SetAttributeParams({
            tokenId: 1,
            attributes: attributes,
            proof: proof
        });

        metadata.setAttributes(params);

        (string[] memory names, IPropertyIPFS.ItemParam[] memory items, IPropertyIPFS.IPFSGroup memory ipfsGroup) = getMockMetadata();

        vm.prank(address(owner));
        metadata.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        metadata.onMinted(1);

        uint16[16] memory newAttributes = metadata.getRawAttributes(1);
        assertEq(keccak256(abi.encode(newAttributes)), keccak256(abi.encode(attributes)));
    }

    function test_SetAttributesAfterOnMinted() external {
        bytes32 root = 0x5e0f333d56d9716c0e2ae5f990981023f2bc6cb23eba6c7d60ba8146af726a8b;

        vm.prank(owner);
        metadata.setAttributeMerkleRoot(root);

        (string[] memory names, IPropertyIPFS.ItemParam[] memory items, IPropertyIPFS.IPFSGroup memory ipfsGroup) = getMockMetadata();

        vm.prank(address(owner));
        metadata.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        metadata.onMinted(1);

        uint16[16] memory attributes;
        attributes[0] = 5;
        attributes[1] = 8;
        attributes[2] = 4;
        attributes[3] = 2;
        attributes[4] = 1;
        attributes[5] = 0;

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0x040ebb2969ff59488f98dc7cd9014aa8b112ba4bf78c2f8bcf03be0fad0d2e0e;

        IMerklePropertyIPFS.SetAttributeParams memory params = IMerklePropertyIPFS.SetAttributeParams({
            tokenId: 1,
            attributes: attributes,
            proof: proof
        });

        metadata.setAttributes(params);

        uint16[16] memory newAttributes = metadata.getRawAttributes(1);
        assertEq(keccak256(abi.encode(newAttributes)), keccak256(abi.encode(attributes)));
    }

    function testRevert_SetMerkleRootNotOwner() external {
        bytes32 root = 0x5e0f333d56d9716c0e2ae5f990981023f2bc6cb23eba6c7d60ba8146af726a8b;

        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        metadata.setAttributeMerkleRoot(root);
    }
}
