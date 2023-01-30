// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IConfigurator} from "./IConfigurator.sol";
import {ICopyright} from "./ICopyright.sol";
import {IArtwork} from "./IArtwork.sol";
import {IMetadata} from "./IMetadata.sol";
import {IRuleset} from "./IRuleset.sol";
import {IRulesetFactory} from "./IRulesetFactory.sol";
import {IERC165} from "./IERC165.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IERC1155Receiver} from "./IERC1155Receiver.sol";

interface ICanvasV1 is IERC165, IERC721Receiver, IERC1155Receiver {
    /**
     * @dev create the `amount` artwork with the `ruleset`, the `metadata`, and the content encoded as `data
     */
    function createArtwork(
        uint256 amount,
        IRuleset ruleset,
        IMetadata metadata,
        bytes calldata data
    ) external returns (uint256 tokenId);

    /**
     * @dev create the `amount` artwork with the `rulesetFactory`, the `metadata`,  the ruleset settings encoded as `rulesetData`, and the content encoded as `data
     */
    function createRulesetAndArtwork(
        uint256 amount,
        IRulesetFactory rulesetFactory,
        IMetadata metadata,
        bytes calldata rulesetData,
        bytes calldata data
    ) external returns (uint256 tokenId);
}
