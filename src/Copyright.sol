// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Unauthorized, AlreadyMinted, NotMinted, InvalidMetadata, InexistenceMetadata, InvalidRuleset, NotUpgradableRuleset, ForbiddenToApply} from "./interfaces/Errors.sol";
import {ICopyright, Property} from "./interfaces/ICopyright.sol";
import {IConfigurator, Action} from "./interfaces/IConfigurator.sol";
import {IMetadataRegistry} from "./interfaces/IMetadataRegistry.sol";
import {IArtwork} from "./interfaces/IArtwork.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IRuleset} from "./interfaces/IRuleset.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC2981} from "./interfaces/IERC2981.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {ERC721} from "./libraries/ERC721.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {ERC165Checker} from "./libraries/ERC165Checker.sol";
import {NFTDescriptor} from "./utils/NFTDescriptor.sol";
import {Artwork} from "./Artwork.sol";

contract Copyright is ICopyright, ERC721("Replisome Copyright", "RPS-CR") {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    IConfigurator public immutable configurator;

    IMetadataRegistry public immutable metadataRegistry;

    IArtwork public immutable artwork;

    uint256 public totalSupply;

    // mapping from tokenId to Property
    mapping(uint256 => Property) internal _propertyOf;

    // mapping from Metadata to metadataId to tokenId
    mapping(IMetadata => mapping(uint256 => uint256))
        internal _tokenIdByMetadata;

    constructor(
        IConfigurator configurator_,
        IMetadataRegistry metadataRegistry_
    ) {
        configurator = configurator_;
        metadataRegistry = metadataRegistry_;
        artwork = new Artwork(configurator_, this);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICopyright).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721Metadata, ERC721)
        returns (string memory)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        string memory name = string(
            abi.encodePacked("Replisome Copyright #", tokenId)
        );
        string memory description = string(
            abi.encodePacked(
                "Copyright #",
                tokenId,
                " is powered by Replisome.xyz"
            )
        );
        return
            NFTDescriptor.constructTokenURI(
                NFTDescriptor.TokenURIParams({
                    name: name,
                    description: description,
                    renderer: configurator.copyrightRenderer(),
                    id: tokenId
                })
            );
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        Property storage property = _propertyOf[tokenId];
        receiver = property.creator;
        royaltyAmount = configurator.getFeeAmount(
            Action.CopyrightSale,
            property.metadata,
            property.metadataId,
            salePrice
        );
    }

    function metadataOf(uint256 tokenId)
        public
        view
        returns (IMetadata metadata, uint256 metadataId)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        Property storage property = _propertyOf[tokenId];
        metadata = property.metadata;
        metadataId = property.metadataId;
    }

    function creatorOf(uint256 tokenId)
        external
        view
        returns (address creator)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        Property storage property = _propertyOf[tokenId];
        creator = property.creator;
    }

    function rulesetOf(uint256 tokenId)
        external
        view
        returns (IRuleset ruleset)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        Property storage property = _propertyOf[tokenId];
        ruleset = property.ruleset;
    }

    function getIngredients(uint256 tokenId)
        public
        view
        returns (uint256[] memory ids, uint256[] memory amounts)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        Property memory property = _propertyOf[tokenId];
        (ids, amounts) = property.metadata.getIngredients(property.metadataId);
    }

    function exists(uint256 tokenId) public view returns (bool ok) {
        ok = _ownerOf[tokenId] != address(0);
    }

    function search(IMetadata metadata, uint256 metadataId)
        public
        view
        returns (uint256 tokenId)
    {
        tokenId = _tokenIdByMetadata[metadata][metadataId];
    }

    function claim(
        address creator,
        IRuleset ruleset,
        IMetadata metadata,
        uint256 metadataId
    ) external {
        if (
            address(ruleset) == address(0) ||
            !address(ruleset).supportsInterface(type(IRuleset).interfaceId)
        ) {
            revert InvalidRuleset(ruleset);
        }
        if (
            address(metadata) == address(0) ||
            !metadataRegistry.isRegistered(metadata)
        ) {
            revert InvalidMetadata(metadata);
        }
        if (!metadata.exists(metadataId)) {
            revert InexistenceMetadata(metadata, metadataId);
        }

        (
            uint256[] memory ingredientIds,
            uint256[] memory ingredientAmounts
        ) = metadata.getIngredients(metadataId);
        uint256 ingredientId;
        for (uint256 i = 0; i < ingredientIds.length; ) {
            ingredientId = ingredientIds[i];
            if (
                _propertyOf[ingredientId].ruleset.canApply(
                    creator,
                    ingredientId,
                    ruleset
                ) < ingredientAmounts[i]
            ) {
                revert ForbiddenToApply(ingredientId);
            }
            unchecked {
                ++i;
            }
        }

        uint256 tokenId = _tokenIdByMetadata[metadata][metadataId];

        if (exists(tokenId)) {
            revert AlreadyMinted(tokenId);
        }

        if (tokenId == uint256(0)) {
            tokenId = ++totalSupply;

            Property storage property = _propertyOf[tokenId];
            property.creator = creator;
            property.ruleset = ruleset;
            property.metadata = metadata;
            property.metadataId = metadataId;

            _tokenIdByMetadata[metadata][metadataId] = tokenId;

            emit RulesetUpdated(tokenId, ruleset);
        }

        _safeMint(creator, tokenId);
        _payProtocolFee(tokenId, Action.CopyrightClaim);
    }

    function waive(uint256 tokenId) external {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }

        address owner = _ownerOf[tokenId];
        if (
            msg.sender != owner &&
            !isApprovedForAll[owner][msg.sender] &&
            msg.sender != getApproved[tokenId]
        ) {
            revert Unauthorized(msg.sender);
        }

        _burn(tokenId);
        _payProtocolFee(tokenId, Action.CopyrightWaive);
    }

    function updateRuleset(uint256 tokenId, IRuleset ruleset) external {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        if (!address(ruleset).supportsInterface(type(IRuleset).interfaceId)) {
            revert InvalidRuleset(ruleset);
        }

        Property storage property = _propertyOf[tokenId];
        if (!property.ruleset.isUpgradable()) {
            revert NotUpgradableRuleset(property.ruleset);
        }

        property.ruleset = ruleset;
        emit RulesetUpdated(tokenId, ruleset);
    }

    function _payProtocolFee(uint256 tokenId, Action action) internal {
        IERC20 token = configurator.feeToken();
        address treasury = configurator.treasury();
        if (address(token) != address(0) && treasury != address(0)) {
            Property storage property = _propertyOf[tokenId];
            uint256 fee = configurator.getFeeAmount(
                action,
                property.metadata,
                property.metadataId,
                1
            );
            token.safeTransferFrom(msg.sender, treasury, fee);
        }
    }
}
