// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ActionType} from "../interfaces/Structs.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IRule} from "../interfaces/IRule.sol";
import {ERC165} from "../libraries/ERC165.sol";

contract CC0Rule is IRule, ERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IRule).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function isUpgradable() external pure returns (bool ok) {
        ok = false;
    }

    function canTransfer(address, uint256) external pure returns (bool ok) {
        ok = true;
    }

    function canCopy(address, uint256) external pure returns (bool ok) {
        ok = true;
    }

    function canBurn(address, uint256) external pure returns (bool ok) {
        ok = true;
    }

    function getRoyaltyReceiver(ActionType)
        external
        pure
        returns (address receiver)
    {
        receiver = address(0);
    }

    function getRoyaltyToken(ActionType) external pure returns (IERC20 token) {
        token = IERC20(address(0));
    }

    function getRoyaltyAmount(ActionType, uint256)
        external
        pure
        returns (uint256 amount)
    {
        amount = uint256(0);
    }
}
