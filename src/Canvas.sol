// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Layer, Action} from "./interfaces/Structs.sol";
import {IArtwork} from "./interfaces/IArtwork.sol";
import {ICanvas} from "./interfaces/ICanvas.sol";
import {IConfigurator} from "./interfaces/IConfigurator.sol";
import {ICopyright} from "./interfaces/ICopyright.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IRuleset} from "./interfaces/IRuleset.sol";
import {ERC165} from "./libraries/ERC165.sol";
import {ERC721Receiver} from "./libraries/ERC721Receiver.sol";
import {ERC1155Receiver} from "./libraries/ERC1155Receiver.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";

contract Canvas is ICanvas, ERC165, ERC721Receiver, ERC1155Receiver {
    using SafeERC20 for IERC20;

    IConfigurator public immutable configurator;
    ICopyright public immutable copyright;
    IArtwork public immutable artwork;

    constructor(
        IConfigurator configurator_,
        ICopyright copyright_,
        IArtwork artwork_
    ) {
        configurator = configurator_;
        copyright = copyright_;
        artwork = artwork_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICanvas).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function create(
        uint256 amount,
        IRuleset ruleset,
        IMetadata metadata,
        bytes calldata data
    ) external returns (uint256 tokenId) {
        uint256 metadataId = metadata.create(data);

        _payCopyrightFee(metadata, metadataId, Action.CopyrightClaim);

        copyright.claim(msg.sender, ruleset, metadata, metadataId);
        tokenId = copyright.search(metadata, metadataId);

        if (amount > 0) {
            _payArtworkFee(tokenId, amount, Action.ArtworkCopy);

            artwork.copy(msg.sender, tokenId, amount);
        }
    }

    function waive(uint256 tokenId) external {
        (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
            tokenId
        );

        _payCopyrightFee(metadata, metadataId, Action.CopyrightWaive);

        copyright.waive(tokenId);
    }

    function copy(uint256 tokenId, uint256 amount) external {
        if (amount > 0) {
            _payArtworkFee(tokenId, amount, Action.ArtworkCopy);

            artwork.copy(msg.sender, tokenId, amount);
        }
    }

    function burn(uint256 tokenId, uint256 amount) external {
        if (amount > 0) {
            _payArtworkFee(tokenId, amount, Action.ArtworkBurn);

            artwork.burn(msg.sender, tokenId, amount);
        }
    }

    // this function should only dry run
    function appraise(
        uint256 amount,
        IMetadata metadata,
        bytes calldata data
    )
        public
        returns (
            uint256 metadataId,
            uint256 claimFee,
            uint256 copyFee
        )
    {
        metadataId = metadata.create(data);
        claimFee = configurator.getFeeAmount(
            Action.CopyrightClaim,
            metadata,
            metadataId,
            1
        );
        copyFee = configurator.getFeeAmount(
            Action.ArtworkCopy,
            metadata,
            metadataId,
            amount
        );
    }

    struct FeeItem {
        uint256 tokenId;
        address receiver;
        IERC20 token;
        uint256 amount;
        Action action;
    }

    function getRoyaltyFees(uint256 tokenId, uint256 amount)
        external
        view
        returns (FeeItem[] memory feeItems)
    {
        IRuleset ruleset = copyright.rulesetOf(tokenId);
        (
            uint256[] memory ingredientIds,
            uint256[] memory ingredientAmounts
        ) = copyright.getIngredients(tokenId);

        uint256 idsLength = ingredientIds.length;
        feeItems = new FeeItem[](idsLength + 2);
        address royaltyReceiver;
        IERC20 royaltyToken;
        uint256 royaltyAmount;

        (royaltyReceiver, royaltyToken, royaltyAmount) = ruleset.getCopyRoyalty(
            amount
        );
        feeItems[0] = FeeItem({
            tokenId: tokenId,
            receiver: royaltyReceiver,
            token: royaltyToken,
            amount: royaltyAmount,
            action: Action.ArtworkCopy
        });

        (royaltyReceiver, royaltyToken, royaltyAmount) = ruleset.getBurnRoyalty(
            amount
        );
        feeItems[1] = FeeItem({
            tokenId: tokenId,
            receiver: royaltyReceiver,
            token: royaltyToken,
            amount: royaltyAmount,
            action: Action.ArtworkBurn
        });

        for (uint256 i = 0; i < idsLength; ) {
            ruleset = copyright.rulesetOf(ingredientIds[i]);
            (royaltyReceiver, royaltyToken, royaltyAmount) = ruleset
                .getUtilizeRoyalty(ingredientAmounts[i] * amount);
            feeItems[i + 2] = FeeItem({
                tokenId: ingredientIds[i],
                receiver: royaltyReceiver,
                token: royaltyToken,
                amount: royaltyAmount,
                action: Action.ArtworkUtilize
            });

            unchecked {
                ++i;
            }
        }
    }

    function _payCopyrightFee(
        IMetadata metadata,
        uint256 metadataId,
        Action action
    ) internal {
        IERC20 token = configurator.feeToken();
        if (address(token) != address(0)) {
            uint256 fee = configurator.getFeeAmount(
                action,
                metadata,
                metadataId,
                1
            );
            token.safeTransferFrom(msg.sender, address(this), fee);
            token.safeIncreaseAllowance(address(copyright), fee);
        }
    }

    function _payArtworkFee(
        uint256 tokenId,
        uint256 amount,
        Action action
    ) internal {
        IRuleset ruleset = copyright.rulesetOf(tokenId);
        (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
            tokenId
        );

        IERC20 feeToken = configurator.feeToken();
        uint256 protocolFee = configurator.getFeeAmount(
            action,
            metadata,
            metadataId,
            amount
        );
        if (address(feeToken) != address(0)) {
            feeToken.safeTransferFrom(msg.sender, address(this), protocolFee);
            feeToken.safeIncreaseAllowance(address(artwork), protocolFee);
        }

        IERC20 royaltyToken;
        uint256 royaltyAmount;
        if (action == Action.ArtworkCopy) {
            (, royaltyToken, royaltyAmount) = ruleset.getCopyRoyalty(amount);

            if (address(royaltyToken) != address(0)) {
                royaltyToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    royaltyAmount
                );
                royaltyToken.safeIncreaseAllowance(
                    address(artwork),
                    royaltyAmount
                );
            }

            (
                uint256[] memory ingredientIds,
                uint256[] memory ingredientAmounts
            ) = copyright.getIngredients(tokenId);
            for (uint256 i = 0; i < ingredientIds.length; ) {
                ruleset = copyright.rulesetOf(ingredientIds[i]);
                (, royaltyToken, royaltyAmount) = ruleset.getUtilizeRoyalty(
                    ingredientAmounts[i] * amount
                );

                if (address(royaltyToken) != address(0)) {
                    royaltyToken.safeTransferFrom(
                        msg.sender,
                        address(this),
                        royaltyAmount
                    );
                    royaltyToken.safeIncreaseAllowance(
                        address(artwork),
                        royaltyAmount
                    );
                }

                unchecked {
                    ++i;
                }
            }
        } else if (action == Action.ArtworkBurn) {
            (, royaltyToken, royaltyAmount) = ruleset.getBurnRoyalty(amount);
            if (address(royaltyToken) != address(0)) {
                royaltyToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    royaltyAmount
                );
                royaltyToken.safeIncreaseAllowance(
                    address(artwork),
                    royaltyAmount
                );
            }
        }
    }
}
