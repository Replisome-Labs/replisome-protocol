// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IRule} from "./IRule.sol";
import {IMetadata} from "./IMetadata.sol";

struct Property {
    address creator;
    IRule rule;
    IMetadata metadata;
    uint256 metadataId;
}

struct Layer {
    uint256 tokenId;
    TransformParam[] transforms;
}

struct LayerLayout {
    uint256 width;
    uint256 height;
}

struct TransformParam {
    TransformType transformType;
    uint256 value;
}

enum TransformType {
    TranslateX,
    TranslateY,
    Rotate,
    Flip
}

enum ActionType {
    Transfer,
    Copy,
    Burn,
    ArtworkSale,
    CopyrightSale
}
