// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IRule} from "./IRule.sol";
import {IMetadata} from "./IMetadata.sol";

enum ActionType {
    Transfer,
    Copy,
    Burn,
    ArtworkSale,
    CopyrightSale
}

enum Rotate {
    D0,
    D90,
    D180,
    D270
}

enum Flip {
    None,
    Horizontal,
    Vertical
}

struct Layer {
    uint256 tokenId;
    Rotate rotate;
    Flip flip;
    uint256 translateX;
    uint256 translateY;
}

struct Property {
    address creator;
    IRule rule;
    IMetadata metadata;
    uint256 metadataId;
}
