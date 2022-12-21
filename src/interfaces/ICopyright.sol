// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Action} from "./Structs.sol";
import {IArtwork} from "./IArtwork.sol";
import {IConfigurator} from "./IConfigurator.sol";
import {IMetadata} from "./IMetadata.sol";
import {IMetadataRegistry} from "./IMetadataRegistry.sol";
import {IRuleset} from "./IRuleset.sol";
import {IERC20} from "./IERC20.sol";
import {IERC721} from "./IERC721.sol";
import {IERC721Metadata} from "./IERC721Metadata.sol";
import {IERC2981} from "./IERC2981.sol";

interface ICopyright is IERC721, IERC721Metadata, IERC2981 {
    event RulesetUpdated(uint256 indexed tokenId, IRuleset indexed ruleset);

    function configurator() external view returns (IConfigurator target);

    function metadataRegistry()
        external
        view
        returns (IMetadataRegistry target);

    function artwork() external view returns (IArtwork target);

    function totalSupply() external view returns (uint256 amount);

    function metadataOf(uint256 tokenId)
        external
        view
        returns (IMetadata metadata, uint256 metadataId);

    function creatorOf(uint256 tokenId) external view returns (address creator);

    function rulesetOf(uint256 tokenId)
        external
        view
        returns (IRuleset ruleset);

    function getIngredients(uint256 tokenId)
        external
        view
        returns (uint256[] memory ids, uint256[] memory amounts);

    function exists(uint256 tokenId) external view returns (bool ok);

    function search(IMetadata metadata, uint256 metadataId)
        external
        view
        returns (uint256 tokenId);

    function claim(
        address creator,
        IRuleset ruleset,
        IMetadata metadata,
        uint256 metadataId
    ) external;

    function waive(uint256 tokenId) external;

    function updateRuleset(uint256 tokenId, IRuleset ruleset) external;
}
