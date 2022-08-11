// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC1155} from "./IERC1155.sol";
import {ActionType} from "./Structs.sol";

interface IArtwork is IERC1155 {
    function configurator() external view returns (address target);

    function copyright() external view returns (address target);

    function royaltyInfoByAction(
        uint256 tokenId,
        uint256 salePrice,
        address buyer,
        ActionType actionType
    )
        external
        view
        returns (
            address receiver,
            uint256 royaltyAmount,
            IERC20 token
        );

    function ownedBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256 amount);

    function usedBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256 amount);

    function copy() external;

    function burn() external;
}
