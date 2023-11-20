// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

contract MetadataTest is Test {
    bytes initStrings;

    function setMockInitStrings() internal virtual {
        setInitStrings(
            "Mock Token",
            "MOCK",
            "This is a mock token",
            "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j",
            "https://nouns.build",
            "http://localhost:5000/render"
        );
    }

    function setInitStrings(
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _contractImage,
        string memory _contractURI,
        string memory _rendererBase
    ) internal virtual {
        initStrings = abi.encode(_name, _symbol, _description, _contractImage, _contractURI, _rendererBase);
    }
}
