// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Action} from "./interfaces/Structs.sol";
import {Unauthorized, Untransferable, Uncopiable, Unburnable} from "./interfaces/Errors.sol";
import {IArtwork} from "./interfaces/IArtwork.sol";
import {IConfigurator} from "./interfaces/IConfigurator.sol";
import {ICopyright} from "./interfaces/ICopyright.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IERC1155} from "./interfaces/IERC1155.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC2981} from "./interfaces/IERC2981.sol";
import {ERC1155} from "./libraries/ERC1155.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {Strings} from "./libraries/Strings.sol";
import {ArtworkDescriptor} from "./utils/ArtworkDescriptor.sol";

contract Artwork is IArtwork, ERC1155 {
    using SafeERC20 for IERC20;
    using Strings for uint256;

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
        override(ERC1155, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IArtwork).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = copyright.getRoyaltyReceiver(Action.ArtworkSale, tokenId);
        royaltyAmount = copyright.getRoyaltyAmount(
            Action.ArtworkSale,
            tokenId,
            salePrice
        );
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155)
        returns (string memory)
    {
        string memory name = string(
            abi.encodePacked("HiggsPixel Artwork #", tokenId.toString())
        );
        string memory description = string(
            abi.encodePacked(
                "Artwork #",
                tokenId.toString(),
                " is powered by HiggsPixel"
            )
        );
        (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
            tokenId
        );
        ArtworkDescriptor.TokenURIParams memory params = ArtworkDescriptor
            .TokenURIParams({
                name: name,
                description: description,
                metadata: metadata,
                metadataId: metadataId
            });
        return ArtworkDescriptor.constructTokenURI(params);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public override(ERC1155, IERC1155) {
        if (!copyright.canDo(from, Action.ArtworkTransfer, tokenId, amount)) {
            revert Untransferable();
        }
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override(ERC1155, IERC1155) {
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                if (
                    !copyright.canDo(
                        from,
                        Action.ArtworkTransfer,
                        tokenIds[i],
                        amounts[i]
                    )
                ) {
                    revert Untransferable();
                }
            }
        }
        super.safeBatchTransferFrom(from, to, tokenIds, amounts, data);
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

        if (!copyright.canDo(account, Action.ArtworkCopy, tokenId, amount)) {
            revert Uncopiable();
        }

        (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
            tokenId
        );

        // pay protocol fee
        _payFee(
            configurator.feeToken(),
            msg.sender,
            configurator.treatury(),
            configurator.getFeeAmount(
                Action.ArtworkCopy,
                metadata,
                metadataId,
                amount
            )
        );

        // pay royalty fee
        _payFee(
            copyright.getRoyaltyToken(Action.ArtworkCopy, tokenId),
            msg.sender,
            copyright.getRoyaltyReceiver(Action.ArtworkCopy, tokenId),
            copyright.getRoyaltyAmount(Action.ArtworkCopy, tokenId, amount)
        );

        _consume(account, tokenId, amount);
        _mint(account, tokenId, amount, "");
        ownedBalanceOf[account][tokenId] += amount;
    }

    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external {
        if (msg.sender != account && !isApprovedForAll[account][msg.sender]) {
            revert Unauthorized(msg.sender);
        }

        if (!copyright.canDo(account, Action.ArtworkBurn, tokenId, amount)) {
            revert Unburnable();
        }

        (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
            tokenId
        );

        // pay protocol fee
        _payFee(
            configurator.feeToken(),
            msg.sender,
            configurator.treatury(),
            configurator.getFeeAmount(
                Action.ArtworkBurn,
                metadata,
                metadataId,
                amount
            )
        );

        // pay royalty fee
        _payFee(
            copyright.getRoyaltyToken(Action.ArtworkBurn, tokenId),
            msg.sender,
            copyright.getRoyaltyReceiver(Action.ArtworkBurn, tokenId),
            copyright.getRoyaltyAmount(Action.ArtworkBurn, tokenId, amount)
        );

        _burn(account, tokenId, amount);
        _recycle(account, tokenId, amount);
        ownedBalanceOf[account][tokenId] -= amount;
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
        uint256[] memory usedAmounts = new uint256[](ingredientAmounts.length);
        unchecked {
            for (uint256 i = 0; i < ingredientAmounts.length; i++) {
                usedAmounts[i] = ingredientAmounts[i] * amount;
            }
        }
        _batchBurn(account, ingredientIds, usedAmounts);
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
        uint256[] memory usedAmounts = new uint256[](ingredientAmounts.length);
        unchecked {
            for (uint256 i = 0; i < ingredientAmounts.length; i++) {
                usedAmounts[i] = ingredientAmounts[i] * amount;
            }
        }
        _batchMint(account, ingredientIds, usedAmounts, "");
    }

    function _payFee(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (
            address(token) != address(0) &&
            from != address(0) &&
            to != address(0) &&
            amount != uint256(0)
        ) {
            token.safeTransferFrom(from, to, amount);
        }
    }
}
