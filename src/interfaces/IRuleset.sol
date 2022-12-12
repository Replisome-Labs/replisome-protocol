// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "./IERC165.sol";
import {IERC20} from "./IERC20.sol";
import {Action} from "./Structs.sol";

interface IRuleset is IERC165 {
    function isUpgradable() external view returns (bool ok);

    function canTransfer(address actor)
        external
        view
        returns (uint256 allowance);

    function canCopy(address actor) external view returns (uint256 allowance);

    function canBurn(address actor) external view returns (uint256 allowance);

    function canUse(address actor, IRuleset ruleset)
        external
        view
        returns (uint256 allownace);

    function getRoyaltyReceiver(Action action)
        external
        view
        returns (address receiver);

    function getRoyaltyToken(Action action)
        external
        view
        returns (IERC20 token);

    function getRoyaltyAmount(Action action, uint256 price)
        external
        view
        returns (uint256 amount);
}
