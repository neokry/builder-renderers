// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { MockMetadata } from "./utils/mocks/MockMetadata.sol";
import { MockToken } from "./utils/mocks/MockToken.sol";
import { MetadataTest } from "./utils/MetadataTest.sol";
import { IBaseMetadata } from "../src/IBaseMetadata.sol";

contract BaseMetadataTest is MetadataTest {
    MockMetadata metadata;
    MockToken token;

    address user;
    address owner;

    function setUp() external {
        user = address(0xA11CE);
        owner = address(0xB0B);
        metadata = new MockMetadata();
        token = new MockToken(owner);
    }

    function setupRenderer() private {
        setMockInitStrings();
        metadata.initialize(initStrings, address(token));
    }

    function test_Initilization() external {
        setupRenderer();

        (, , string memory _description, string memory _contractImage, string memory _projectURI, ) = abi.decode(
            initStrings,
            (string, string, string, string, string, string)
        );

        assertEq(metadata.token(), address(token));
        assertEq(metadata.description(), _description);
        assertEq(metadata.contractImage(), _contractImage);
        assertEq(metadata.projectURI(), _projectURI);
    }

    function test_UpdateDescription() external {
        setupRenderer();
        string memory description = "new description";

        vm.prank(owner);
        metadata.updateDescription(description);
        assertEq(metadata.description(), description);
    }

    function test_UpdateContractImage() external {
        setupRenderer();
        string memory contractImage = "https://img.com/123";

        vm.prank(owner);
        metadata.updateContractImage(contractImage);
        assertEq(metadata.contractImage(), contractImage);
    }

    function test_UpdateProjectURI() external {
        setupRenderer();
        string memory projectURI = "https://myproject.com";

        vm.prank(owner);
        metadata.updateProjectURI(projectURI);
        assertEq(metadata.projectURI(), projectURI);
    }

    function test_AddAdditionalProperties() external {
        setupRenderer();

        IBaseMetadata.AdditionalTokenProperty[] memory additionalTokenProperties = new IBaseMetadata.AdditionalTokenProperty[](2);
        additionalTokenProperties[0] = IBaseMetadata.AdditionalTokenProperty({ key: "testing", value: "HELLO", quote: true });
        additionalTokenProperties[1] = IBaseMetadata.AdditionalTokenProperty({
            key: "participationAgreement",
            value: "This is a JSON quoted participation agreement.",
            quote: true
        });

        vm.prank(owner);
        metadata.setAdditionalTokenProperties(additionalTokenProperties);

        IBaseMetadata.AdditionalTokenProperty[] memory properties = metadata.getAdditionalTokenProperties();

        for (uint256 i; i < 0; ++i) {
            assertEq(properties[i].key, additionalTokenProperties[i].key);
            assertEq(properties[i].value, additionalTokenProperties[i].value);
            assertEq(properties[i].quote, additionalTokenProperties[i].quote);
        }
    }

    function testRevert_OnlyOwner() external {
        setupRenderer();
        string memory description = "new description";

        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        metadata.updateDescription(description);

        string memory contractImage = "https://img.com/123";

        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        metadata.updateContractImage(contractImage);

        string memory projectURI = "https://myproject.com";

        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        metadata.updateProjectURI(projectURI);
    }
}
