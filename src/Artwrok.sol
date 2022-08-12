// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Unauthorized, Untransferable, Uncopiable, Unburnable} from "./interfaces/Errors.sol";
import {IArtwork} from "./interfaces/IArtwork.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {ERC1155} from "./libraries/ERC1155.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";

contract Artwork is IArtwork, ERC1155 {
    using SafeERC20 for IERC20;

    IConfigurator public immutable configurator;

    ICopyright public immutable copyright;

    mapping(address => mapping(uint256 => uint256)) public ownedBalanceOf;

    constructor(IConfigurator configurator_, ICopyright copyright_) {
        configurator = configurator_;
        copyright = copyright_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165, IERC1155)
        returns (bool)
    {
        return
            interfaceId == type(IArtwork).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = copyright.getRoyaltyToken(tokenId, ActionType.ArtworkSale);
        royaltyAmount = copyright.getRoyaltyAmount(
            tokenId,
            ActionType.ArtworkSale,
            salePrice
        );
    }

    function uri(uint256 id)
        public
        view
        override(ERC1155)
        returns (string memory)
    {
        return "hello";
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public override(ERC1155) {
        if (!copyright.canDo(from, ActionType.Transfer, tokenId, amount)) {
            revert Untransferable();
        }
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override(ERC1155) {
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                if (
                    !copyright.canDo(
                        from,
                        ActionType.Transfer,
                        tokenIds[i],
                        amounts[i]
                    )
                ) {
                    revert Untransferable();
                }
            }
            }
        }
        super.safeTransferFrom(from, to, tokenIds, amounts, data);
    }

    function usedBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256 amount)
    {
        amount = ownedBalanceOf[account][tokenId] - balanceOf[account][tokenId];
    }

    function copy(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external {
        if (msg.sender != account && !isApprovedForAll[account][msg.sender]) {
            revert Unauthorized(msg.sender);
        }

        if (!copyright.canDo(account, ActionType.Copy, tokenId, amount)) {
            revert Uncopiable();
        }

        // pay protocol fee
        _payFee(
            configurator.getFeeToken(),
            msg.sender,
            configurator.treatury(),
            configurator.getArtworkCopyFee() * amount
        );

        // pay royalty fee
        _payFee(
            copyright.getRoyaltyToken(tokenId, ActionType.Copy),
            msg.sender,
            copyright.getRoyaltyReceiver(tokenId, ActionType.Copy),
            copyright.getRoyaltyAmount(tokenId, ActionType.Copy, amount)
        );

        _consume(account, tokenId, amount);
        _mint(account, tokenId, amount, "");
        ownedBalanceOf[account][tokenId]++;
    }

    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external {
        if (msg.sender != account && !isApprovedForAll[account][msg.sender]) {
            revert Unauthorized(msg.sender);
        }

        if (!copyright.canDo(account, ActionType.Burn, tokenId, amount)) {
            revert Unburnable();
        }

        // pay protocol fee
        _payFee(
            configurator.getFeeToken(),
            msg.sender,
            configurator.treatury(),
            configurator.getArtworkBurnFee() * amount
        );

        // pay royalty fee
        _payFee(
            copyright.getRoyaltyToken(tokenId, ActionType.Burn),
            msg.sender,
            copyright.getRoyaltyReceiver(tokenId, ActionType.Burn),
            copyright.getRoyaltyAmount(tokenId, ActionType.Burn, amount)
        );

        _burn(account, tokenId, amount);
        _recycle(account, tokenId, amount);
        ownedBalanceOf[account][tokenId]--;
    }

    function _consume(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal {
        (
            uint256[] memory ingredientIds,
            uint256[] memory ingredientAmounts
        ) = copyright.getIngredients(tokenId);
        _batchBurn(account, ingredientIds, ingredientAmounts);
    }

    function _recycle(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal {
        (
            uint256[] memory ingredientIds,
            uint256[] memory ingredientAmounts
        ) = copyright.getIngredients(tokenId);
        _batchMint(account, ingredientIds, ingredientAmounts, "");
    }

    function _payFee(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (address(token) != address(0)) {
            token.safeTransferFrom(from, to, amount);
        }
    }
}
