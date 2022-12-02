// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Layer, Action} from "./Structs.sol";
import {IConfigurator} from "./IConfigurator.sol";
import {ICopyright} from "./ICopyright.sol";
import {IArtwork} from "./IArtwork.sol";
import {IMetadata} from "./IMetadata.sol";
import {IRuleset} from "./IRuleset.sol";
import {IERC165} from "./IERC165.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IERC1155Receiver} from "./IERC1155Receiver.sol";

interface ICanvas is IERC165, IERC721Receiver, IERC1155Receiver {
    function configurator() external view returns (IConfigurator target);

    function copyright() external view returns (ICopyright target);

    function artwork() external view returns (IArtwork target);

    function create(
        uint256 amount,
        IRuleset ruleset,
        IMetadata metadata,
        bytes calldata data
    ) external returns (uint256 tokenId);

    function copy(uint256 tokenId, uint256 amount) external;

    function waive(uint256 tokenId) external;

    function burn(uint256 tokenId, uint256 amount) external;

    function estimateFeeAmount(
        Action action,
        uint256 amount,
        IMetadata metadata,
        bytes calldata data
    ) external returns (uint256 price);
}
