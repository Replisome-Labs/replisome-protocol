// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165} from "./IERC165.sol";
import {IERC20} from "./IERC20.sol";

interface IRuleset is IERC165 {
    function isUpgradable() external view returns (bool ok);

    function canTransfer(address actor)
        external
        view
        returns (uint256 allowance);

    function canCopy(address actor) external view returns (uint256 allowance);

    function canBurn(address actor) external view returns (uint256 allowance);

    function canApply(address actor, IRuleset ruleset)
        external
        view
        returns (uint256 allownace);

    function getSaleRoyalty(uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function getCopyRoyalty(uint256 amount)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        );

    function getBurnRoyalty(uint256 amount)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        );

    function getUtilizeRoyalty(uint256 amount)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        );
}
