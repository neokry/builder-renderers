// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { MetadataTest } from "./MetadataTest.sol";
import { IPropertyIPFS } from "../../src/PropertyIPFS/IPropertyIPFS.sol";

contract PropertyIPFSTest is MetadataTest {
    function getMockMetadata()
        internal
        pure
        returns (string[] memory names, IPropertyIPFS.ItemParam[] memory items, IPropertyIPFS.IPFSGroup memory ipfsGroup)
    {
        names = new string[](1);
        names[0] = "testing";

        items = new IPropertyIPFS.ItemParam[](2);
        items[0] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "failure1", isNewProperty: true });
        items[1] = IPropertyIPFS.ItemParam({ propertyId: 0, name: "failure2", isNewProperty: true });

        ipfsGroup = IPropertyIPFS.IPFSGroup({ baseUri: "BASE_URI", extension: "EXTENSION" });
    }
}
