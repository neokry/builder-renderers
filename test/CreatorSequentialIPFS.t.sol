// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { CreatorSequentialIPFS, ICreatorSequentialIPFS } from "../src/CreatorSequentialIPFS/CreatorSequentialIPFS.sol";
import { ISequentialIPFS } from "../src/SequentialIPFS/ISequentialIPFS.sol";
import { MockToken } from "./utils/mocks/MockToken.sol";
import { MetadataTest } from "./utils/MetadataTest.sol";
import { Base64URIDecoder } from "./utils/Base64URIDecoder.sol";

contract MerklePropertyMetadataTest is MetadataTest {
    CreatorSequentialIPFS metadata;
    MockToken token;

    address user;
    address owner;
    address creator;
    address manager;

    function setUp() public {
        user = address(0xA11CE);
        owner = address(0xB0B);
        creator = address(0xC4A704);
        manager = address(0x4A4A6E6);

        metadata = new CreatorSequentialIPFS(manager);
        token = new MockToken(owner);

        setMockInitStrings();

        vm.prank(manager);
        metadata.initialize(initStrings, address(token));
    }

    function test_SetMetadataItem() external {
        vm.prank(owner);
        metadata.setCreator(creator);

        string memory imageURI = "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j";
        string memory contentURI = "ipfs://Fmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8l";

        vm.prank(creator);
        metadata.setMetadataItem(0, imageURI, contentURI);

        ISequentialIPFS.MetadataItem memory item = metadata.getMetadataItem(0);

        assertEq(item.imageURI, imageURI);
        assertEq(item.contentURI, contentURI);
    }

    function test_SetFallbackMetadataItem() external {
        vm.prank(owner);
        metadata.setCreator(creator);

        string memory imageURI = "ipfs://Hmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8n";
        string memory contentURI = "ipfs://Gmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8o";

        vm.prank(creator);
        metadata.setFallbackMetadataItem(imageURI, contentURI);

        ISequentialIPFS.MetadataItem memory item = metadata.getFallbackMetadataItem();
        assertEq(item.imageURI, imageURI);
        assertEq(item.contentURI, contentURI);
    }

    function test_SetManyMetadataItems() external {
        vm.prank(owner);
        metadata.setCreator(creator);

        uint256[] memory indexes = new uint256[](2);
        indexes[0] = 0;
        indexes[1] = 1;

        string[] memory imageURIs = new string[](2);
        imageURIs[0] = "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8q";
        imageURIs[1] = "ipfs://Fmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8r";

        string[] memory contentURIs = new string[](2);
        contentURIs[0] = "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8s";
        contentURIs[1] = "ipfs://Fmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8t";

        vm.prank(creator);
        metadata.setManyMetadataItems(indexes, imageURIs, contentURIs);

        ISequentialIPFS.MetadataItem memory item = metadata.getMetadataItem(0);
        assertEq(item.imageURI, imageURIs[0]);
        assertEq(item.contentURI, contentURIs[0]);

        item = metadata.getMetadataItem(1);
        assertEq(item.imageURI, imageURIs[1]);
        assertEq(item.contentURI, contentURIs[1]);
    }

    function test_DeleteMetadataItem() external {
        vm.prank(owner);
        metadata.setCreator(creator);

        string memory imageURI = "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j";
        string memory contentURI = "ipfs://Fmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8l";

        vm.prank(creator);
        metadata.setMetadataItem(0, imageURI, contentURI);

        ISequentialIPFS.MetadataItem memory item = metadata.getMetadataItem(0);
        assertEq(item.imageURI, imageURI);
        assertEq(item.contentURI, contentURI);
        assertEq(item.active, true);

        vm.prank(creator);
        metadata.deleteMetadataItem(0);

        item = metadata.getMetadataItem(0);
        assertEq(item.imageURI, "");
        assertEq(item.contentURI, "");
        assertEq(item.active, false);
    }

    function test_TokenURI() external {
        vm.prank(owner);
        metadata.setCreator(creator);

        string memory imageURI = "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j";
        string memory contentURI = "ipfs://Fmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8l";

        vm.prank(creator);
        metadata.setMetadataItem(0, imageURI, contentURI);

        /**
        TokenURI Result Pretty JSON:
        {
            "name": "Mock Token #0",
            "description": "This is a mock token",
            "image": "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j",
            "animation_url": "ipfs://Fmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8l"
        }
         */

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", metadata.tokenURI(0));

        emit log(json);

        assertEq(
            json,
            '{"name": "Mock Token #0","description": "This is a mock token","image": "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j","animation_url": "ipfs://Fmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8l"}'
        );
    }

    function test_TokenURINoContent() external {
        vm.prank(owner);
        metadata.setCreator(creator);

        string memory imageURI = "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j";

        vm.prank(creator);
        metadata.setMetadataItem(0, imageURI, "");

        /**
        TokenURI Result Pretty JSON:
        {
            "name": "Mock Token #0",
            "description": "This is a mock token",
            "image": "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j"
        }
         */

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", metadata.tokenURI(0));

        emit log(json);

        assertEq(
            json,
            '{"name": "Mock Token #0","description": "This is a mock token","image": "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j"}'
        );
    }

    function test_TokenURIWithFallback() external {
        vm.prank(owner);
        metadata.setCreator(creator);

        string memory imageURI = "ipfs://Hmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8n";
        string memory contentURI = "ipfs://Gmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8o";

        vm.prank(creator);
        metadata.setFallbackMetadataItem(imageURI, contentURI);

        /**
        TokenURI Result Pretty JSON:
        {
            "name": "Mock Token #0",
            "description": "This is a mock token",
            "image": "ipfs://Hmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8n",
            "animation_url": "ipfs://Gmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8o"
        }
         */

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", metadata.tokenURI(0));

        emit log(json);

        assertEq(
            json,
            '{"name": "Mock Token #0","description": "This is a mock token","image": "ipfs://Hmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8n","animation_url": "ipfs://Gmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8o"}'
        );
    }

    function testRevert_OnlyCreator() external {
        string memory imageURI = "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j";
        string memory contentURI = "ipfs://Fmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8l";

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("ONLY_CREATOR()"));
        metadata.setMetadataItem(0, imageURI, contentURI);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("ONLY_CREATOR()"));
        metadata.setFallbackMetadataItem(imageURI, contentURI);

        uint256[] memory indexes = new uint256[](2);
        indexes[0] = 0;
        indexes[1] = 1;

        string[] memory imageURIs = new string[](2);
        imageURIs[0] = "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8q";
        imageURIs[1] = "ipfs://Fmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8r";

        string[] memory contentURIs = new string[](2);
        contentURIs[0] = "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8s";
        contentURIs[1] = "ipfs://Fmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8t";

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("ONLY_CREATOR()"));
        metadata.setManyMetadataItems(indexes, imageURIs, contentURIs);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("ONLY_CREATOR()"));
        metadata.deleteMetadataItem(0);
    }

    function testRevert_OnlyOwner() external {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        metadata.setCreator(creator);
    }
}
