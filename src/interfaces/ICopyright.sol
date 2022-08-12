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

    function propertyInfoOf(uint256 tokenId)
        external
        view
        returns (Property property);

    function canDo(
        address owner,
        ActionType action,
        uint256 tokenId,
        uint256 amount
    ) external view returns (bool ok);

    function getRoyaltyToken(ActionType action, uint256 tokenId)
        external
        view
        returns (IERC20 token);

    function getRoyaltyReceiver(ActionType action, uint256 tokenId)
        external
        view
        returns (address receiver);

    function getRoyaltyAmount(
        ActionType action,
        uint256 tokenId,
        uint256 value
    ) external view returns (uint256 amount);

    function getIngredients(uint256 tokenId)
        external
        view
        returns (uint256[] ids, uint256[] amounts);

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
