// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165} from "../interfaces/IERC165.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IRuleset} from "../interfaces/IRuleset.sol";
import {ERC165} from "../libraries/ERC165.sol";

contract BasicFees is IRuleset, ERC165 {
    uint256 internal immutable _saleRoyaltyFraction; // denominated by 10000
    uint256 internal immutable _copyPrice;
    uint256 internal immutable _burnPrice;
    uint256 internal immutable _utilizePrice;
    address internal immutable _royaltyReceiver;
    IERC20 internal immutable _royaltyToken;
    bool internal immutable _isUpgradable;

    constructor(
        bool isUpgradable_,
        address royaltyReceiver_,
        IERC20 royaltyToken_,
        uint256 saleRoyaltyFraction_,
        uint256 copyPrice_,
        uint256 burnPrice_,
        uint256 utilizePrice_
    ) {
        _isUpgradable = isUpgradable_;
        _royaltyReceiver = royaltyReceiver_;
        _royaltyToken = royaltyToken_;
        _saleRoyaltyFraction = saleRoyaltyFraction_;
        _copyPrice = copyPrice_;
        _burnPrice = burnPrice_;
        _utilizePrice = utilizePrice_;
    }

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

    function isUpgradable() external view returns (bool ok) {
        ok = _isUpgradable;
    }

    function canTransfer(address) external pure returns (uint256 allowance) {
        allowance = type(uint256).max;
    }

    function canCopy(address) external pure returns (uint256 allowance) {
        allowance = type(uint256).max;
    }

    function canBurn(address) external pure returns (uint256 allowance) {
        allowance = type(uint256).max;
    }

    function canApply(address, IRuleset)
        external
        pure
        returns (uint256 allowance)
    {
        allowance = type(uint256).max;
    }

    function getSaleRoyalty(uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * _saleRoyaltyFraction) / 10000;
    }

    function getCopyRoyalty(uint256 amount)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        )
    {
        receiver = _royaltyReceiver;
        token = _royaltyToken;
        royaltyAmount = _copyPrice * amount;
    }

    function getBurnRoyalty(uint256 amount)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        )
    {
        receiver = _royaltyReceiver;
        token = _royaltyToken;
        royaltyAmount = _burnPrice * amount;
    }

    function getUtilizeRoyalty(uint256 amount)
        external
        view
        returns (
            address receiver,
            IERC20 token,
            uint256 royaltyAmount
        )
    {
        receiver = _royaltyReceiver;
        token = _royaltyToken;
        royaltyAmount = _utilizePrice * amount;
    }
}
