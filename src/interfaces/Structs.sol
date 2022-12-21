// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IRuleset} from "./IRuleset.sol";
import {IMetadata} from "./IMetadata.sol";
import {RasterEngine} from "../utils/RasterEngine.sol";

enum Action {
    CopyrightClaim,
    CopyrightWaive,
    CopyrightSale,
    ArtworkCopy,
    ArtworkBurn,
    ArtworkUtilize
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
    uint120 translateX;
    uint120 translateY;
}

struct Meta {
    uint256 width;
    uint256 height;
    uint256[] ingredients;
    mapping(uint256 => uint256) ingredientAmountOf;
    RasterEngine.Palette palette;
    bytes content;
}

struct Property {
    address creator;
    IRuleset ruleset;
    IMetadata metadata;
    uint256 metadataId;
}
