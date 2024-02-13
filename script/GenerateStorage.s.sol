// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console2 } from "forge-std/Script.sol";
import { IBaseMetadata } from "../src/IBaseMetadata.sol";

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

        console2.log("SequentialIPFSRenderer:");
        console2.logBytes32(keccak256(abi.encode(uint256(keccak256("nounsbuilder.storage.SequentialIPFSRenderer")) - 1)) & ~bytes32(uint256(0xff)));

        console2.log("CreatorSequentialIPFSRenderer:");
        console2.logBytes32(
            keccak256(abi.encode(uint256(keccak256("nounsbuilder.storage.CreatorSequentialIPFSRenderer")) - 1)) & ~bytes32(uint256(0xff))
        );

        console2.log("IBaseMetadata:");
        console2.logBytes4(type(IBaseMetadata).interfaceId);
    }
}
