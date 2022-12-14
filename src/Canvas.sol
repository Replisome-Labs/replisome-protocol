// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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
        (uint256 metadataId, , , uint256 allFee) = createAndAppraise(
            amount,
            metadata,
            data
        );

        _payFee(configurator.feeToken(), msg.sender, address(this), allFee);

        copyright.claim(msg.sender, ruleset, metadata, metadataId);
        tokenId = copyright.search(metadata, metadataId);

        if (amount > 0) {
            _payFee(
                copyright.getRoyaltyToken(Action.ArtworkCopy, tokenId),
                msg.sender,
                address(this),
                copyright.getRoyaltyAmount(Action.ArtworkCopy, tokenId, amount)
            );

            artwork.copy(msg.sender, tokenId, amount);
        }
    }

    function waive(uint256 tokenId) external {
        (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
            tokenId
        );

        _payFee(
            configurator.feeToken(),
            msg.sender,
            address(this),
            configurator.getFeeAmount(
                Action.CopyrightWaive,
                metadata,
                metadataId,
                1
            )
        );

        copyright.waive(tokenId);
    }

    function copy(uint256 tokenId, uint256 amount) external {
        if (amount > 0) {
            (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
                tokenId
            );

            _payFee(
                configurator.feeToken(),
                msg.sender,
                address(this),
                configurator.getFeeAmount(
                    Action.ArtworkCopy,
                    metadata,
                    metadataId,
                    amount
                )
            );

            _payFee(
                copyright.getRoyaltyToken(Action.ArtworkCopy, tokenId),
                msg.sender,
                address(this),
                copyright.getRoyaltyAmount(Action.ArtworkCopy, tokenId, amount)
            );

            artwork.copy(msg.sender, tokenId, amount);
        }
    }

    function burn(uint256 tokenId, uint256 amount) external {
        if (amount > 0) {
            (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
                tokenId
            );

            _payFee(
                configurator.feeToken(),
                msg.sender,
                address(this),
                configurator.getFeeAmount(
                    Action.ArtworkBurn,
                    metadata,
                    metadataId,
                    amount
                )
            );

            _payFee(
                copyright.getRoyaltyToken(Action.ArtworkBurn, tokenId),
                msg.sender,
                address(this),
                copyright.getRoyaltyAmount(Action.ArtworkBurn, tokenId, amount)
            );

            artwork.burn(msg.sender, tokenId, amount);
        }
    }

    function createAndAppraise(
        uint256 amount,
        IMetadata metadata,
        bytes calldata data
    )
        public
        returns (
            uint256 metadataId,
            uint256 claimFee,
            uint256 copyFee,
            uint256 allFee
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
        allFee = claimFee + copyFee;
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
