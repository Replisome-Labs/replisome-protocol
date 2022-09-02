// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Layer, ActionType} from "./interfaces/Structs.sol";
import {IArtwork} from "./interfaces/IArtwork.sol";
import {ICanvas} from "./interfaces/ICanvas.sol";
import {IConfigurator} from "./interfaces/IConfigurator.sol";
import {ICopyright} from "./interfaces/ICopyright.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IRule} from "./interfaces/IRule.sol";
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
        IRule rule,
        IMetadata metadata,
        bytes calldata drawings
    ) external {
        _payFee(
            configurator.feeToken(),
            msg.sender,
            address(this),
            configurator.copyrightClaimFee() +
                (configurator.artworkCopyFee() * amount)
        );

        Layer[] memory layers = new Layer[](0);
        uint256 tokenId = _createAndClaim(rule, metadata, layers, drawings);

        if (amount > 0) {
            _payFee(
                copyright.getRoyaltyToken(ActionType.Copy, tokenId),
                msg.sender,
                address(this),
                copyright.getRoyaltyAmount(ActionType.Copy, tokenId, amount)
            );

            artwork.copy(msg.sender, tokenId, amount);
        }
    }

    function compose(
        uint256 amount,
        IRule rule,
        IMetadata metadata,
        Layer[] calldata layers,
        bytes calldata drawings
    ) external {
        _payFee(
            configurator.feeToken(),
            msg.sender,
            address(this),
            configurator.copyrightClaimFee() +
                (configurator.artworkCopyFee() * amount)
        );

        uint256 tokenId = _createAndClaim(rule, metadata, layers, drawings);

        if (amount > 0) {
            _payFee(
                copyright.getRoyaltyToken(ActionType.Copy, tokenId),
                msg.sender,
                address(this),
                copyright.getRoyaltyAmount(ActionType.Copy, tokenId, amount)
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
                configurator.artworkCopyFee() * amount
            );

            _payFee(
                copyright.getRoyaltyToken(ActionType.Copy, tokenId),
                msg.sender,
                address(this),
                copyright.getRoyaltyAmount(ActionType.Copy, tokenId, amount)
            );

            artwork.copy(msg.sender, tokenId, amount);
        }
    }

    function waive(uint256 tokenId) external {
        _payFee(
            configurator.feeToken(),
            msg.sender,
            address(this),
            configurator.copyrightWaiveFee()
        );

        copyright.waive(tokenId);
    }

    function burn(uint256 tokenId, uint256 amount) external {
        if (amount > 0) {
            _payFee(
                configurator.feeToken(),
                msg.sender,
                address(this),
                configurator.artworkBurnFee()
            );

            _payFee(
                copyright.getRoyaltyToken(ActionType.Burn, tokenId),
                msg.sender,
                address(this),
                copyright.getRoyaltyAmount(ActionType.Burn, tokenId, amount)
            );

            artwork.burn(msg.sender, tokenId, amount);
        }
    }

    function _createAndClaim(
        IRule rule,
        IMetadata metadata,
        Layer[] memory layers,
        bytes memory drawings
    ) internal returns (uint256 tokenId) {
        uint256 metadataId = metadata.create(layers, drawings);
        copyright.claim(msg.sender, rule, metadata, metadataId);
        tokenId = copyright.search(metadata, metadataId);
        copyright.safeTransferFrom(address(this), msg.sender, tokenId);
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
