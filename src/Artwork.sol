// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Action} from "./interfaces/Structs.sol";
import {Unauthorized, ForbiddenToTransfer, ForbiddenToCopy, ForbiddenToBurn, LengthMismatch, UnsafeRecipient} from "./interfaces/Errors.sol";
import {IArtwork} from "./interfaces/IArtwork.sol";
import {IConfigurator} from "./interfaces/IConfigurator.sol";
import {ICopyright} from "./interfaces/ICopyright.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IRuleset} from "./interfaces/IRuleset.sol";
import {INFTRenderer} from "./interfaces/INFTRenderer.sol";
import {IERC1155} from "./interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "./interfaces/IERC1155MetadataURI.sol";
import {IERC1155Receiver} from "./interfaces/IERC1155Receiver.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC2981} from "./interfaces/IERC2981.sol";
import {ERC1155} from "./libraries/ERC1155.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {Strings} from "./libraries/Strings.sol";
import {Math} from "./libraries/Math.sol";
import {NFTDescriptor} from "./utils/NFTDescriptor.sol";

contract Artwork is IArtwork, ERC1155 {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    IConfigurator public immutable configurator;

    ICopyright public immutable copyright;

    // mapping from account to tokenId to ownedBalance
    mapping(address => mapping(uint256 => uint256)) public ownedBalanceOf;

    // mapping from account to tokenId to allowance
    mapping(address => mapping(uint256 => uint256)) public canTransfer;

    // mapping from account to tokenId to allowance
    mapping(address => mapping(uint256 => uint256)) public canCopy;

    // mapping from account to tokenId to allowance
    mapping(address => mapping(uint256 => uint256)) public canBurn;

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
        IRuleset ruleset = copyright.rulesetOf(tokenId);
        (receiver, royaltyAmount) = ruleset.getSaleRoyalty(salePrice);
    }

    function uri(uint256 tokenId)
        public
        view
        override(IERC1155MetadataURI, ERC1155)
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
        return
            NFTDescriptor.constructTokenURI(
                NFTDescriptor.TokenURIParams({
                    name: name,
                    description: description,
                    renderer: INFTRenderer(address(metadata)),
                    id: metadataId
                })
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public override(ERC1155, IERC1155) {
        uint256 allowed = canTransfer[from][tokenId];
        if (allowed < amount) {
            allowed = resetTransferAllowance(from, tokenId);
        }
        if (allowed < amount) {
            revert ForbiddenToTransfer(tokenId);
        }
        if (allowed != type(uint256).max) {
            canTransfer[from][tokenId] = allowed - amount;
        }

        ownedBalanceOf[from][tokenId] -= amount;
        ownedBalanceOf[to][tokenId] += amount;
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override(ERC1155, IERC1155) {
        if (tokenIds.length != amounts.length) {
            revert LengthMismatch();
        }

        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert Unauthorized(msg.sender);
        }

        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < tokenIds.length; ) {
            id = tokenIds[i];
            amount = amounts[i];

            uint256 allowed = canTransfer[from][id];
            if (allowed < amount) {
                allowed = resetTransferAllowance(from, id);
            }
            if (allowed < amount) {
                revert ForbiddenToTransfer(id);
            }
            if (allowed != type(uint256).max) {
                canTransfer[from][id] = allowed - amount;
            }

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;
            ownedBalanceOf[from][id] -= amount;
            ownedBalanceOf[to][id] += amount;

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, tokenIds, amounts);

        if (
            to.code.length == 0
                ? to == address(0)
                : IERC1155Receiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    tokenIds,
                    amounts,
                    data
                ) != IERC1155Receiver.onERC1155BatchReceived.selector
        ) {
            revert UnsafeRecipient(to);
        }
    }

    function usedBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256 amount)
    {
        amount = ownedBalanceOf[account][tokenId] - balanceOf[account][tokenId];
    }

    function resetTransferAllowance(address account, uint256 tokenId)
        public
        returns (uint256 allowance)
    {
        allowance = type(uint256).max; // permission is open by default

        (uint256[] memory ingredientIds, ) = copyright.getIngredients(tokenId);
        unchecked {
            for (uint256 i = 0; i < ingredientIds.length; i++) {
                allowance = Math.min(
                    allowance,
                    canTransfer[account][ingredientIds[i]]
                );
            }
        }

        IRuleset ruleset = copyright.rulesetOf(tokenId);
        if (address(ruleset) != address(0)) {
            allowance = Math.min(allowance, ruleset.canTransfer(account));
        }

        canTransfer[account][tokenId] = allowance;
    }

    function resetCopyAllowance(address account, uint256 tokenId)
        public
        returns (uint256 allowance)
    {
        allowance = type(uint256).max; // permission is open by default

        (uint256[] memory ingredientIds, ) = copyright.getIngredients(tokenId);
        unchecked {
            for (uint256 i = 0; i < ingredientIds.length; i++) {
                allowance = Math.min(
                    allowance,
                    canCopy[account][ingredientIds[i]]
                );
            }
        }

        IRuleset ruleset = copyright.rulesetOf(tokenId);
        if (address(ruleset) != address(0)) {
            allowance = Math.min(allowance, ruleset.canCopy(account));
        }

        canCopy[account][tokenId] = allowance;
    }

    function resetBurnAllowance(address account, uint256 tokenId)
        public
        returns (uint256 allowance)
    {
        allowance = type(uint256).max; // permission is open by default

        (uint256[] memory ingredientIds, ) = copyright.getIngredients(tokenId);
        unchecked {
            for (uint256 i = 0; i < ingredientIds.length; i++) {
                allowance = Math.min(
                    allowance,
                    canBurn[account][ingredientIds[i]]
                );
            }
        }

        IRuleset ruleset = copyright.rulesetOf(tokenId);
        if (address(ruleset) != address(0)) {
            allowance = Math.min(allowance, ruleset.canBurn(account));
        }

        canBurn[account][tokenId] = allowance;
    }

    function copy(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external {
        if (msg.sender != account && !isApprovedForAll[account][msg.sender]) {
            revert Unauthorized(msg.sender);
        }

        uint256 allowed = canCopy[account][tokenId];
        if (allowed < amount) {
            allowed = resetCopyAllowance(account, tokenId);
        }
        if (allowed < amount) {
            revert ForbiddenToCopy(tokenId);
        }
        if (allowed != type(uint256).max) {
            canCopy[account][tokenId] = allowed - amount;
        }

        ownedBalanceOf[account][tokenId] += amount;
        _consume(account, tokenId, amount);
        _mint(account, tokenId, amount, "");

        _payProtocolFee(tokenId, amount, Action.ArtworkCopy);
        _payCopyRoyalty(tokenId, amount);
    }

    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external {
        if (msg.sender != account && !isApprovedForAll[account][msg.sender]) {
            revert Unauthorized(msg.sender);
        }

        uint256 allowed = canCopy[account][tokenId];
        if (allowed < amount) {
            allowed = resetBurnAllowance(account, tokenId);
        }
        if (allowed < amount) {
            revert ForbiddenToBurn(tokenId);
        }
        if (allowed != type(uint256).max) {
            canBurn[account][tokenId] = allowed - amount;
        }

        ownedBalanceOf[account][tokenId] -= amount;
        _recycle(account, tokenId, amount);
        _burn(account, tokenId, amount);

        _payProtocolFee(tokenId, amount, Action.ArtworkBurn);
        _payBurnRoyalty(tokenId, amount);
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

        uint256 idsLength = ingredientIds.length;
        if (idsLength > 0) {
            uint256[] memory usedAmounts = new uint256[](idsLength);
            uint256 ingredientId;

            for (uint256 i = 0; i < idsLength; ) {
                ingredientId = ingredientIds[i];
                usedAmounts[i] = ingredientAmounts[i] * amount;
                balanceOf[account][ingredientId] -= usedAmounts[i];

                _payUtilizeRoyalty(ingredientId, usedAmounts[i]);

                unchecked {
                    ++i;
                }
            }

            emit Utilized(account, ingredientIds, usedAmounts);
        }
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

        uint256 idsLength = ingredientIds.length;
        if (idsLength > 0) {
            uint256[] memory usedAmounts = new uint256[](idsLength);

            for (uint256 i = 0; i < idsLength; ) {
                usedAmounts[i] = ingredientAmounts[i] * amount;
                balanceOf[account][ingredientIds[i]] += usedAmounts[i];

                unchecked {
                    ++i;
                }
            }

            emit Unutilized(account, ingredientIds, usedAmounts);
        }
    }

    function _payCopyRoyalty(uint256 tokenId, uint256 amount) internal {
        IRuleset ruleset = copyright.rulesetOf(tokenId);
        (address receiver, IERC20 token, uint256 royaltyAmount) = ruleset
            .getCopyRoyalty(amount);
        if (address(token) != address(0) && receiver != address(0)) {
            token.safeTransferFrom(msg.sender, receiver, royaltyAmount);
            emit RoyaltyTransfer(
                msg.sender,
                receiver,
                token,
                royaltyAmount,
                Action.ArtworkCopy
            );
        }
    }

    function _payBurnRoyalty(uint256 tokenId, uint256 amount) internal {
        IRuleset ruleset = copyright.rulesetOf(tokenId);
        (address receiver, IERC20 token, uint256 royaltyAmount) = ruleset
            .getBurnRoyalty(amount);

        if (address(token) != address(0) && receiver != address(0)) {
            token.safeTransferFrom(msg.sender, receiver, royaltyAmount);
            emit RoyaltyTransfer(
                msg.sender,
                receiver,
                token,
                royaltyAmount,
                Action.ArtworkBurn
            );
        }
    }

    function _payUtilizeRoyalty(uint256 tokenId, uint256 amount) internal {
        IRuleset ruleset = copyright.rulesetOf(tokenId);
        (address receiver, IERC20 token, uint256 royaltyAmount) = ruleset
            .getUtilizeRoyalty(amount);

        if (address(token) != address(0) && receiver != address(0)) {
            token.safeTransferFrom(msg.sender, receiver, royaltyAmount);
            emit RoyaltyTransfer(
                msg.sender,
                receiver,
                token,
                royaltyAmount,
                Action.ArtworkUtilize
            );
        }
    }

    function _payProtocolFee(
        uint256 tokenId,
        uint256 amount,
        Action action
    ) internal {
        IERC20 token = configurator.feeToken();
        address treasury = configurator.treatury();
        if (address(token) != address(0) && treasury != address(0)) {
            (IMetadata metadata, uint256 metadataId) = copyright.metadataOf(
                tokenId
            );
            uint256 fee = configurator.getFeeAmount(
                action,
                metadata,
                metadataId,
                amount
            );
            token.safeTransferFrom(msg.sender, treasury, fee);
        }
    }
}
