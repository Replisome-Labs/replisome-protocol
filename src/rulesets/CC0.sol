// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165} from "../interfaces/IERC165.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IRuleset} from "../interfaces/IRuleset.sol";
import {ERC165} from "../libraries/ERC165.sol";

contract CC0 is IRuleset, ERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IRuleset).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function isUpgradable() external pure returns (bool ok) {
        ok = false;
    }

    function canTransfer(address, uint256)
        external
        pure
        returns (uint256 allowance)
    {
        allowance = type(uint256).max;
    }

    function canCopy(address, uint256)
        external
        pure
        returns (uint256 allowance)
    {
        allowance = type(uint256).max;
    }

    function canBurn(address, uint256)
        external
        pure
        returns (uint256 allowance)
    {
        allowance = type(uint256).max;
    }

    function canApply(
        address,
        uint256,
        IRuleset
    ) external pure returns (uint256 allowance) {
        allowance = type(uint256).max;
    }

    function getSaleRoyalty(uint256)
        external
        pure
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(0);
        royaltyAmount = uint256(0);
    }

    function getCopyRoyalty(uint256)
        external
        pure
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        )
    {
        receiver = address(0);
        token = IERC20(address(0));
        royaltyAmount = uint256(0);
    }

    function getBurnRoyalty(uint256)
        external
        pure
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        )
    {
        receiver = address(0);
        token = IERC20(address(0));
        royaltyAmount = uint256(0);
    }

    function getUtilizeRoyalty(uint256)
        external
        pure
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        )
    {
        receiver = address(0);
        token = IERC20(address(0));
        royaltyAmount = uint256(0);
    }
}
