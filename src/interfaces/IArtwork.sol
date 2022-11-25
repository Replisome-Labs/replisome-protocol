// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConfigurator} from "./IConfigurator.sol";
import {ICopyright} from "./ICopyright.sol";
import {IERC1155} from "./IERC1155.sol";
import {IERC2981} from "./IERC2981.sol";

interface IArtwork is IERC1155, IERC2981 {
    function configurator() external view returns (IConfigurator target);

    function copyright() external view returns (ICopyright target);

    function ownedBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256 amount);

    function usedBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256 amount);

    function copy(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external;

    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external;
}
