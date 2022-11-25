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
        IRuleset rule,
        IMetadata metadata,
        bytes calldata data
    ) external returns (uint256 tokenId) {
        _payFee(
            configurator.feeToken(),
            msg.sender,
            address(this),
            configurator.getFeeAmount(Action.CopyrightClaim, data, 1)
        );

        tokenId = _createAndClaim(rule, metadata, data);

        if (amount > 0) {
            _payFee(
                copyright.getRoyaltyToken(Action.ArtworkCopy, tokenId),
                msg.sender,
                address(this),
                copyright.getRoyaltyAmount(Action.ArtworkCopy, tokenId, amount)
            );

            _payFee(
                configurator.feeToken(),
                msg.sender,
                address(this),
                configurator.getFeeAmount(Action.ArtworkCopy, tokenId, amount)
            );

            artwork.copy(msg.sender, tokenId, amount);
        }
    }

    function copy(uint256 tokenId, uint256 amount) external {
        if (amount > 0) {
            _payFee(
                configurator.feeToken(),
                msg.sender,
                address(this),
                configurator.getFeeAmount(Action.ArtworkCopy, tokenId, amount)
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

    function waive(uint256 tokenId) external {
        _payFee(
            configurator.feeToken(),
            msg.sender,
            address(this),
            configurator.getFeeAmount(Action.CopyrightWaive, tokenId, 1)
        );

        copyright.waive(tokenId);
    }

    function burn(uint256 tokenId, uint256 amount) external {
        if (amount > 0) {
            _payFee(
                configurator.feeToken(),
                msg.sender,
                address(this),
                configurator.getFeeAmount(Action.ArtworkBurn, tokenId, amount)
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

    function _createAndClaim(
        IRuleset rule,
        IMetadata metadata,
        bytes calldata data
    ) internal returns (uint256 tokenId) {
        uint256 metadataId = metadata.create(data);
        copyright.claim(msg.sender, rule, metadata, metadataId);
        tokenId = copyright.search(metadata, metadataId);
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
