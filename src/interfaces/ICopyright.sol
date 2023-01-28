// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IArtwork} from "./IArtwork.sol";
import {IConfigurator, Action} from "./IConfigurator.sol";
import {IMetadata} from "./IMetadata.sol";
import {IMetadataRegistry} from "./IMetadataRegistry.sol";
import {IRuleset} from "./IRuleset.sol";
import {IERC20} from "./IERC20.sol";
import {IERC721} from "./IERC721.sol";
import {IERC721Metadata} from "./IERC721Metadata.sol";
import {IERC2981} from "./IERC2981.sol";

struct Property {
    address creator;
    IRuleset ruleset;
    IMetadata metadata;
    uint256 metadataId;
}

interface ICopyright is IERC721, IERC721Metadata, IERC2981 {
    /**
     * @dev Emits when the `ruleset` of the `tokenId` token is updated
     */
    event RulesetUpdated(uint256 indexed tokenId, IRuleset indexed ruleset);

    /**
     * @dev Returns the address of configurator
     */
    function configurator() external view returns (IConfigurator target);

    /**
     * @dev Returns the address of metadata registry
     */
    function metadataRegistry()
        external
        view
        returns (IMetadataRegistry target);

    /**
     * @dev Returns the address of artwork
     */
    function artwork() external view returns (IArtwork target);

    /**
     * @dev Returns the amount of copyright in existence.
     */
    function totalSupply() external view returns (uint256 amount);

    /**
     * @dev Returns the metadata address and the metadata id of the `tokenId` token
     */
    function metadataOf(uint256 tokenId)
        external
        view
        returns (IMetadata metadata, uint256 metadataId);

    /**
     * @dev Returns the creator address of the `tokenId` token
     */
    function creatorOf(uint256 tokenId) external view returns (address creator);

    /**
     * @dev Returns the ruleset address of the `tokenId` token
     */
    function rulesetOf(uint256 tokenId)
        external
        view
        returns (IRuleset ruleset);

    /**
     * @dev Returns id and amount of tokens that ara composed into the `tokenId` token
     */
    function getIngredients(uint256 tokenId)
        external
        view
        returns (uint256[] memory ids, uint256[] memory amounts);

    /**
     * @dev Returns true if the `tokenId` token has an owner
     */
    function exists(uint256 tokenId) external view returns (bool ok);

    /**
     * @dev Returns tokenId of the token whose metadata is defined by `metadata` and 'metadataId`
     */
    function search(IMetadata metadata, uint256 metadataId)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev mint copyright token
     * Emits a {Transfer} event
     */
    function claim(
        address creator,
        IRuleset ruleset,
        IMetadata metadata,
        uint256 metadataId
    ) external;

    /**
     * @dev burn the `tokenId` token
     * Emits a {Transfer} event
     */
    function waive(uint256 tokenId) external;

    /**
     * @dev update the `ruleset` address of the `tokenId` token
     * Emits a {RulesetUpdated} event
     */
    function updateRuleset(uint256 tokenId, IRuleset ruleset) external;
}
