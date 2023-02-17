// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165} from "./IERC165.sol";
import {IERC20} from "./IERC20.sol";

interface IRuleset is IERC165 {
    /**
     * @dev Returns true if the ruleset can be upgradable.
     */
    function isUpgradable() external view returns (bool ok);

    /**
     * @dev Returns the amount of artwork that can be transfered by the `actor`.
     */
    function canTransfer(address actor, uint256 tokenId)
        external
        view
        returns (uint256 allowance);

    /**
     * @dev Returns the amount of artwork that can be reproducied by the `actor`.
     */
    function canCopy(address actor, uint256 tokenId)
        external
        view
        returns (uint256 allowance);

    /**
     * @dev Returns the amount of artwork that can be burn by the `actor`.
     */
    function canBurn(address actor, uint256 tokenId)
        external
        view
        returns (uint256 allowance);

    /**
     * @dev Returns the amount of artwork that can be applied by the `actor`.
     */
    function canApply(
        address actor,
        uint256 tokenId,
        IRuleset ruleset
    ) external view returns (uint256 allownace);

    /**
     * @dev Returns the `receiver` and the `royaltyAmount` depended on the `salePrice`.
     */
    function getSaleRoyalty(uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    /**
     * @dev Returns the `receiver`, the `token`, the `royaltyAmount` of royalty information when the artwork is copy `amount` times.
     */
    function getCopyRoyalty(uint256 amount)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        );

    /**
     * @dev Returns the `receiver`, the `token`, the `royaltyAmount` of royalty information when the artwork is burn `amount` times.
     */
    function getBurnRoyalty(uint256 amount)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        );

    /**
     * @dev Returns the `receiver`, the `token`, the `royaltyAmount` of royalty information when the artwork is utilized `amount` times.
     */
    function getUtilizeRoyalty(uint256 amount)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        );
}
