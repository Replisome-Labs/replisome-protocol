// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "./IERC165.sol";
import {ActionType} from "./Structs.sol";

interface IRule is IERC165 {
    function isUpgradable() external view returns (bool ok);

    function canTransfer(
        address actor,
        address from,
        address to,
        uint256 amount
    ) external view returns (bool ok);

    function canCopy(address actor, uint256 amount)
        external
        view
        returns (bool ok);

    function canBurn(address actor, uint256 amount)
        external
        view
        returns (bool ok);

    function getRoyaltyReceiver(ActionType actionType)
        external
        view
        returns (address receiver);

    function getRoyaltyToken(ActionType actionType)
        external
        view
        returns (IERC20 token);

    function getRoyaltyAmount(ActionType actionType, uint256 price)
        external
        view
        returns (uint256 amount);

    function getCopyrightRoyalty(uint256 price)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}
