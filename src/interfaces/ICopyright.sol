// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "./IERC721.sol";
import {IERC2981} from "./IERC2981.sol";
import {IMetadata} from "./IMetadata.sol";
import {IRule} from "./IRule.sol";
import {Property, Layer} from "./Structs.sol";

interface ICopyright is IERC721, IERC2981 {
    event PropertyCreated(uint256 indexed tokenId, Property property);

    event PropertyRuleUpdated(uint256 indexed tokenId, IRule indexed rule);

    function metadataOf(uint256 tokenId)
        external
        view
        returns (IMetadata metadata, uint256 metadataId);

    function ruleOf(uint256 tokenId) external view returns (IRule rule);

    function ingredientsOf(uint256 tokenId)
        external
        view
        returns (uint256[] memory ingredients);

    function ingredientAmountOf(uint256 tokenId, uint256 layerTokenId)
        external
        view
        returns (uint256 amount);

    function exist(uint256 tokenId) external view returns (bool ok);

    function search(IMetadata metadata, uint256 metadataId)
        external
        view
        returns (uint256 tokenId);

    function claim(
        address creator,
        IRule rule,
        IMetadata metadata,
        Layer[] memory layers,
        bytes calldata drawings
    ) external;

    function waive(uint256 tokenId) external;

    function updateRule(uint256 tokenId, IRule rule) external;
}
