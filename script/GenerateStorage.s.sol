// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console2 } from "forge-std/Script.sol";

contract GenerateScript is Script {
    function setUp() public {}

    function run() public pure {
        console2.log("BaseMetadataRenderer:");
        console2.logBytes32(keccak256(abi.encode(uint256(keccak256("nounsbuilder.storage.BaseMetadataRenderer")) - 1)) & ~bytes32(uint256(0xff)));

        console2.log("PropertyIPFSRenderer:");
        console2.logBytes32(keccak256(abi.encode(uint256(keccak256("nounsbuilder.storage.PropertyIPFSRenderer")) - 1)) & ~bytes32(uint256(0xff)));

        console2.log("MerklePropertyIPFSRenderer:");
        console2.logBytes32(
            keccak256(abi.encode(uint256(keccak256("nounsbuilder.storage.MerklePropertyIPFSRenderer")) - 1)) & ~bytes32(uint256(0xff))
        );

        uint256 tokenId = 1;

        uint16[16] memory values;
        values[0] = 5;
        values[1] = 8;
        values[2] = 4;
        values[3] = 2;
        values[4] = 1;
        values[5] = 0;

        console2.logBytes(abi.encode(tokenId, values));
    }
}
