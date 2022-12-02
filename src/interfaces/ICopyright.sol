// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Property, Action} from "./Structs.sol";
import {IConfigurator} from "./IConfigurator.sol";
import {IMetadataRegistry} from "./IMetadataRegistry.sol";
import {IRuleset} from "./IRuleset.sol";
import {IMetadata} from "./IMetadata.sol";
import {IERC20} from "./IERC20.sol";
import {IERC721} from "./IERC721.sol";
import {IERC2981} from "./IERC2981.sol";

interface ICopyright is IERC721, IERC2981 {
    event PropertyCreated(uint256 indexed tokenId, Property property);

    event PropertyRulesetUpdated(
        uint256 indexed tokenId,
        IRuleset indexed ruleset
    );

    function configurator() external view returns (IConfigurator target);

    function metadataRegistry()
        external
        view
        returns (IMetadataRegistry target);

    function propertyInfoOf(uint256 tokenId)
        external
        view
        returns (Property memory property);

    function metadataOf(uint256 tokenId)
        external
        view
        returns (IMetadata metadata, uint256 metadataId);

    function canDo(
        address owner,
        Action action,
        uint256 tokenId,
        uint256 amount
    ) external view returns (bool ok);

    function getRoyaltyToken(Action action, uint256 tokenId)
        external
        view
        returns (IERC20 token);

    function getRoyaltyReceiver(Action action, uint256 tokenId)
        external
        view
        returns (address receiver);

    function getRoyaltyAmount(
        Action action,
        uint256 tokenId,
        uint256 value
    ) external view returns (uint256 amount);

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

    function updateRule(uint256 tokenId, IRuleset ruleset) external;
}
