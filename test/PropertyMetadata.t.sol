// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { PropertyIPFS, IPropertyIPFS } from "../src/PropertyIPFS/PropertyIPFS.sol";
import { IBaseMetadata } from "../src/IBaseMetadata.sol";
import { MockToken } from "./utils/mocks/MockToken.sol";
import { PropertyIPFSTest } from "./utils/PropertyIPFSTest.sol";
import { Base64URIDecoder } from "./utils/Base64URIDecoder.sol";

contract PropertyMetadataTest is PropertyIPFSTest {
    PropertyIPFS metadata;
    MockToken token;

    address user;
    address owner;
    address manager;

    function setUp() external {
        user = address(0xA11CE);
        owner = address(0xB0B);
        manager = address(0x4A4A6E6);

        metadata = new PropertyIPFS(manager);
        token = new MockToken(owner);

        setMockInitStrings();

        vm.prank(manager);
        metadata.initialize(initStrings, address(token));
    }

    function testRevert_MustAddAtLeastOneItemWithProperty() public {
        string[] memory names = new string[](2);
        names[0] = "test";
        names[1] = "more test";

        IPropertyIPFS.ItemParam[] memory items = new IPropertyIPFS.ItemParam[](0);

        IPropertyIPFS.IPFSGroup memory ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "BASE_URI", extension: "EXTENSION" });

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("ONE_PROPERTY_AND_ITEM_REQUIRED()"));
        metadata.addProperties(names, items, ipfsGroup);

        // Attempt to mint token #0
        vm.prank(address(token));
        bool response = metadata.onMinted(0);

        assertFalse(response);
    }

    function testRevert_MustAddAtLeastOnePropertyWithItem() public {
        string[] memory names = new string[](0);

        IPropertyIPFS.ItemParam[] memory items = new IPropertyIPFS.ItemParam[](2);
        items[0] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "failure", isNewProperty: false });
        items[1] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "failure", isNewProperty: true });

        IPropertyIPFS.IPFSGroup memory ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "BASE_URI", extension: "EXTENSION" });

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("ONE_PROPERTY_AND_ITEM_REQUIRED()"));
        metadata.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        bool response = metadata.onMinted(0);
        assertFalse(response);
    }

    function testRevert_MustAddItemForExistingProperty() public {
        string[] memory names = new string[](1);
        names[0] = "testing";

        IPropertyIPFS.ItemParam[] memory items = new IPropertyIPFS.ItemParam[](2);
        items[0] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "failure", isNewProperty: true });
        items[1] = IPropertyIPFS.ItemParam({ propertyId: 2, name: "failure", isNewProperty: false });

        IPropertyIPFS.IPFSGroup memory ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "BASE_URI", extension: "EXTENSION" });

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("INVALID_PROPERTY_SELECTED(uint256)", 2));
        metadata.addProperties(names, items, ipfsGroup);

        // 0th token minted
        vm.prank(address(token));
        bool response = metadata.onMinted(0);
        assertFalse(response);
    }

    function test_AddNewPropertyWithItems() public {
        string[] memory names = new string[](1);
        names[0] = "testing";

        IPropertyIPFS.ItemParam[] memory items = new IPropertyIPFS.ItemParam[](2);
        items[0] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "failure1", isNewProperty: true });
        items[1] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "failure2", isNewProperty: true });

        IPropertyIPFS.IPFSGroup memory ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "BASE_URI", extension: "EXTENSION" });

        vm.prank(owner);
        metadata.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        bool response = metadata.onMinted(0);
        assertTrue(response);
    }

    function testRevert_CannotExceedMaxProperties() public {
        string[] memory names = new string[](16);

        IPropertyIPFS.ItemParam[] memory items = new IPropertyIPFS.ItemParam[](16);

        for (uint256 j; j < 16; j++) {
            names[j] = "aaa"; // Add random properties

            items[j].name = "aaa"; // Add random items
            items[j].propertyId = uint16(j); // Make sure all properties have items
            items[j].isNewProperty = true;
        }

        IPropertyIPFS.IPFSGroup memory group = IPropertyIPFS.IPFSGroup("aaa", "aaa");

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("TOO_MANY_PROPERTIES()"));
        metadata.addProperties(names, items, group);
    }

    function test_deleteAndRecreateProperties() public {
        string[] memory names = new string[](1);
        names[0] = "testing";

        IPropertyIPFS.ItemParam[] memory items = new IPropertyIPFS.ItemParam[](2);
        items[0] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "failure1", isNewProperty: true });
        items[1] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "failure2", isNewProperty: true });

        IPropertyIPFS.IPFSGroup memory ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "BASE_URI", extension: "EXTENSION" });

        vm.prank(owner);
        metadata.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        bool response = metadata.onMinted(0);
        assertTrue(response);

        names = new string[](1);
        names[0] = "testing upsert";

        items = new IPropertyIPFS.ItemParam[](2);
        items[0] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "UPSERT1", isNewProperty: true });
        items[1] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "UPSERT2", isNewProperty: true });

        ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "NEW_BASE_URI", extension: "EXTENSION" });

        vm.prank(owner);
        metadata.deleteAndRecreateProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        response = metadata.onMinted(0);
        assertTrue(response);
    }

    function test_ContractURI() public {
        /**
            base64 -d
            eyJuYW1lIjogIk1vY2sgVG9rZW4iLCJkZXNjcmlwdGlvbiI6ICJUaGlzIGlzIGEgbW9jayB0b2tlbiIsImltYWdlIjogImlwZnM6Ly9RbWV3N1RkeUduajZZUlVqUVI2OHNVSk4zMjM5TVlYUkQ4dXhvd3hGNnJHSzhqIiwiZXh0ZXJuYWxfdXJsIjogImh0dHBzOi8vbm91bnMuYnVpbGQifQ==
            {"name": "Mock Token","description": "This is a mock token","image": "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j","external_url": "https://nouns.build"}
        */
        assertEq(
            metadata.contractURI(),
            "data:application/json;base64,eyJuYW1lIjogIk1vY2sgVG9rZW4iLCJkZXNjcmlwdGlvbiI6ICJUaGlzIGlzIGEgbW9jayB0b2tlbiIsImltYWdlIjogImlwZnM6Ly9RbWV3N1RkeUduajZZUlVqUVI2OHNVSk4zMjM5TVlYUkQ4dXhvd3hGNnJHSzhqIiwiZXh0ZXJuYWxfdXJsIjogImh0dHBzOi8vbm91bnMuYnVpbGQifQ=="
        );
    }

    function test_AddAdditionalPropertiesWithAddress() public {
        string[] memory names = new string[](1);
        names[0] = "mock-property";

        IPropertyIPFS.ItemParam[] memory items = new IPropertyIPFS.ItemParam[](1);
        items[0].propertyId = 0;
        items[0].name = "mock-item";
        items[0].isNewProperty = true;

        IPropertyIPFS.IPFSGroup memory ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "https://nouns.build/api/test/", extension: ".json" });

        vm.prank(owner);
        metadata.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        metadata.onMinted(0);

        IBaseMetadata.AdditionalTokenProperty[] memory additionalTokenProperties = new IBaseMetadata.AdditionalTokenProperty[](2);
        additionalTokenProperties[0] = IBaseMetadata.AdditionalTokenProperty({ key: "testing", value: "HELLO", quote: true });
        additionalTokenProperties[1] = IBaseMetadata.AdditionalTokenProperty({
            key: "participationAgreement",
            value: "This is a JSON quoted participation agreement.",
            quote: true
        });
        vm.prank(owner);
        metadata.setAdditionalTokenProperties(additionalTokenProperties);

        /**
            Token URI additional properties result:

            {
                "name": "Mock Token #0",
                "description": "This is a mock token",
                "image": "http://localhost:5000/render?contractAddress=0x5615deb798bb3e4dfa0139dfa1b3d433cc23b72f&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json",
                "properties": {
                    "mock-property": "mock-item"
                },
                "testing": "HELLO",
                "participationAgreement": "This is a JSON quoted participation agreement."
            }
        
        */

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", metadata.tokenURI(0));
        assertEq(
            json,
            '{"name": "Mock Token #0","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x5615deb798bb3e4dfa0139dfa1b3d433cc23b72f&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json","properties": {"mock-property": "mock-item"},"testing": "HELLO","participationAgreement": "This is a JSON quoted participation agreement."}'
        );
    }

    function test_AddAndClearAdditionalPropertiesWithAddress() public {
        string[] memory names = new string[](1);
        names[0] = "mock-property";

        IPropertyIPFS.ItemParam[] memory items = new IPropertyIPFS.ItemParam[](1);
        items[0].propertyId = 0;
        items[0].name = "mock-item";
        items[0].isNewProperty = true;

        IPropertyIPFS.IPFSGroup memory ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "https://nouns.build/api/test/", extension: ".json" });

        vm.prank(owner);
        metadata.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        metadata.onMinted(0);

        IBaseMetadata.AdditionalTokenProperty[] memory additionalTokenProperties = new IBaseMetadata.AdditionalTokenProperty[](2);
        additionalTokenProperties[0] = IBaseMetadata.AdditionalTokenProperty({ key: "testing", value: "HELLO", quote: true });
        additionalTokenProperties[1] = IBaseMetadata.AdditionalTokenProperty({
            key: "participationAgreement",
            value: "This is a JSON quoted participation agreement.",
            quote: true
        });
        vm.prank(owner);
        metadata.setAdditionalTokenProperties(additionalTokenProperties);

        string memory withAdditionalTokenProperties = metadata.tokenURI(0);

        IBaseMetadata.AdditionalTokenProperty[] memory clearedTokenProperties = new IBaseMetadata.AdditionalTokenProperty[](0);
        vm.prank(owner);
        metadata.setAdditionalTokenProperties(clearedTokenProperties);

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", metadata.tokenURI(0));

        // Ensure no additional properties are sent
        assertEq(
            json,
            '{"name": "Mock Token #0","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x5615deb798bb3e4dfa0139dfa1b3d433cc23b72f&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json","properties": {"mock-property": "mock-item"}}'
        );

        assertTrue(keccak256(bytes(withAdditionalTokenProperties)) != keccak256(bytes(metadata.tokenURI(0))));
    }

    function test_UnicodePropertiesWithAddress() public {
        string[] memory names = new string[](1);
        names[0] = unicode"mock-⌐ ◨-◨-.∆property";

        IPropertyIPFS.ItemParam[] memory items = new IPropertyIPFS.ItemParam[](1);
        items[0].propertyId = 0;
        items[0].name = unicode" ⌐◨-◨ ";
        items[0].isNewProperty = true;

        IPropertyIPFS.IPFSGroup memory ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "https://nouns.build/api/test/", extension: ".json" });

        vm.prank(owner);
        metadata.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        metadata.onMinted(0);

        IBaseMetadata.AdditionalTokenProperty[] memory additionalTokenProperties = new IBaseMetadata.AdditionalTokenProperty[](2);
        additionalTokenProperties[0] = IBaseMetadata.AdditionalTokenProperty({ key: "testing", value: "HELLO", quote: true });
        additionalTokenProperties[1] = IBaseMetadata.AdditionalTokenProperty({
            key: "participationAgreement",
            value: "This is a JSON quoted participation agreement.",
            quote: true
        });
        vm.prank(owner);
        metadata.setAdditionalTokenProperties(additionalTokenProperties);

        string memory withAdditionalTokenProperties = metadata.tokenURI(0);

        IBaseMetadata.AdditionalTokenProperty[] memory clearedTokenProperties = new IBaseMetadata.AdditionalTokenProperty[](0);
        vm.prank(owner);
        metadata.setAdditionalTokenProperties(clearedTokenProperties);

        // Ensure no additional properties are sent

        // result: {"name": "Mock Token #0","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x5615deb798bb3e4dfa0139dfa1b3d433cc23b72f&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-%e2%8c%90%20%e2%97%a8-%e2%97%a8-.%e2%88%86property%2f%20%e2%8c%90%e2%97%a8-%e2%97%a8%20.json","properties": {"mock-⌐ ◨-◨-.∆property": " ⌐◨-◨ "}}
        // JSON parse:
        // {
        //   name: 'Mock Token #0',
        //   description: 'This is a mock token',
        //   image: 'http://localhost:5000/render?contractAddress=0x5615deb798bb3e4dfa0139dfa1b3d433cc23b72f&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-%e2%8c%90%20%e2%97%a8-%e2%97%a8-.%e2%88%86property%2f%20%e2%8c%90%e2%97%a8-%e2%97%a8%20.json',
        //   properties: { 'mock-⌐ ◨-◨-.∆property': ' ⌐◨-◨ ' }
        // }
        // > decodeURIComponent('https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-%e2%8c%90%20%e2%97%a8-%e2%97%a8-.%e2%88%86property%2f%20%e2%8c%90%e2%97%a8-%e2%97%a8%20.json')
        // 'https://nouns.build/api/test/mock-⌐ ◨-◨-.∆property/ ⌐◨-◨ .json'

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", metadata.tokenURI(0));

        assertEq(
            json,
            unicode'{"name": "Mock Token #0","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x5615deb798bb3e4dfa0139dfa1b3d433cc23b72f&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-%e2%8c%90%20%e2%97%a8-%e2%97%a8-.%e2%88%86property%2f%20%e2%8c%90%e2%97%a8-%e2%97%a8%20.json","properties": {"mock-⌐ ◨-◨-.∆property": " ⌐◨-◨ "}}'
        );

        assertTrue(keccak256(bytes(withAdditionalTokenProperties)) != keccak256(bytes(metadata.tokenURI(0))));
    }

    function test_TokenURIWithAddress() public {
        string[] memory names = new string[](1);
        names[0] = "mock-property";

        IPropertyIPFS.ItemParam[] memory items = new IPropertyIPFS.ItemParam[](1);
        items[0].propertyId = 0;
        items[0].name = "mock-item";
        items[0].isNewProperty = true;

        IPropertyIPFS.IPFSGroup memory ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "https://nouns.build/api/test/", extension: ".json" });

        vm.prank(owner);
        metadata.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        metadata.onMinted(0);

        /**
        TokenURI Result Pretty JSON:
        {
            "name": "Mock Token #0",
            "description": "This is a mock token",
            "image": "http://localhost:5000/render?contractAddress=0xa37a694f029389d5167808761c1b62fcef775288&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json",
            "properties": {
                "mock-property": "mock-item"
            }
        }
         */

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", metadata.tokenURI(0));

        assertEq(
            json,
            '{"name": "Mock Token #0","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x5615deb798bb3e4dfa0139dfa1b3d433cc23b72f&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json","properties": {"mock-property": "mock-item"}}'
        );
    }
}
