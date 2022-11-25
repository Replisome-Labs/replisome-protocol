// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IRuleset} from "./IRuleset.sol";
import {IMetadata} from "./IMetadata.sol";

enum Action {
    ArtworkTransfer,
    ArtworkCopy,
    ArtworkBurn,
    ArtworkSale,
    CopyrightTransfer,
    CopyrightClaim,
    CopyrightWaive,
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
    IRuleset rule;
    IMetadata metadata;
    uint256 metadataId;
}
