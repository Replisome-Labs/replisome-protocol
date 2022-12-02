// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Property, Layer, Action} from "./interfaces/Structs.sol";
import {Unauthorized, AlreadyMinted, NotMinted, InvalidRule, InvalidMetadata, NotRegisteredMetadata, InexistenceMetadata} from "./interfaces/Errors.sol";
import {ICopyright} from "./interfaces/ICopyright.sol";
import {IConfigurator} from "./interfaces/IConfigurator.sol";
import {IMetadataRegistry} from "./interfaces/IMetadataRegistry.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {ICopyrightRenderer} from "./interfaces/ICopyrightRenderer.sol";
import {IRuleset} from "./interfaces/IRuleset.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC2981} from "./interfaces/IERC2981.sol";
import {ERC721} from "./libraries/ERC721.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {ERC165Checker} from "./libraries/ERC165Checker.sol";
import {CopyrightDescriptor} from "./utils/CopyrightDescriptor.sol";

contract Copyright is ICopyright, ERC721("HiggsPixel Copyright", "HPCR") {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    IConfigurator public immutable configurator;

    IMetadataRegistry public immutable metadataRegistry;

    uint256 public totalSupply;

    // mapping from tokenId to Property
    mapping(uint256 => Property) internal _propertyInfoOf;

    // mapping from Metadata to metadataId to tokenId
    mapping(IMetadata => mapping(uint256 => uint256))
        internal _tokenIdByMetadata;

    constructor(
        IConfigurator configurator_,
        IMetadataRegistry metadataRegistry_
    ) {
        configurator = configurator_;
        metadataRegistry = metadataRegistry_;
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
        override(ERC721)
        returns (string memory)
    {
        string memory name = string(
            abi.encodePacked("HiggsPixel Copyright #", tokenId)
        );
        string memory description = string(
            abi.encodePacked(
                "Copyright #",
                tokenId,
                " is powered by HiggsPixel"
            )
        );
        ICopyrightRenderer renderer = configurator.copyrightRenderer();
        CopyrightDescriptor.TokenURIParams memory params = CopyrightDescriptor
            .TokenURIParams({
                name: name,
                description: description,
                renderer: renderer,
                tokenId: tokenId
            });
        return CopyrightDescriptor.constructTokenURI(params);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = getRoyaltyReceiver(Action.CopyrightSale, tokenId);
        royaltyAmount = getRoyaltyAmount(
            Action.CopyrightSale,
            tokenId,
            salePrice
        );
    }

    function propertyInfoOf(uint256 tokenId)
        public
        view
        returns (Property memory property)
    {
        property = _propertyInfoOf[tokenId];
    }

    function metadataOf(uint256 tokenId)
        public
        view
        returns (IMetadata metadata, uint256 metadataId)
    {
        Property storage property = _propertyInfoOf[tokenId];
        metadata = property.metadata;
        metadataId = property.metadataId;
    }

    function canDo(
        address owner,
        Action action,
        uint256 tokenId,
        uint256 amount
    ) public view returns (bool ok) {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        IRuleset ruleset = _propertyInfoOf[tokenId].ruleset;
        if (address(ruleset) == address(0)) {
            // All permission is open if ruleset is empty
            ok = true;
        }
        if (action == Action.ArtworkTransfer) {
            ok = ruleset.canTransfer(owner, amount);
        }
        if (action == Action.ArtworkCopy) {
            ok = ruleset.canCopy(owner, amount);
        }
        if (action == Action.ArtworkBurn) {
            ok = ruleset.canBurn(owner, amount);
        }
    }

    function getRoyaltyToken(Action action, uint256 tokenId)
        public
        view
        returns (IERC20 token)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        IRuleset ruleset = _propertyInfoOf[tokenId].ruleset;
        if (address(ruleset) == address(0)) {
            token = IERC20(address(0));
        } else {
            token = ruleset.getRoyaltyToken(action);
        }
    }

    function getRoyaltyReceiver(Action action, uint256 tokenId)
        public
        view
        returns (address receiver)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        IRuleset ruleset = _propertyInfoOf[tokenId].ruleset;
        if (address(ruleset) == address(0)) {
            receiver = address(0);
        } else {
            receiver = ruleset.getRoyaltyReceiver(action);
        }
    }

    function getRoyaltyAmount(
        Action action,
        uint256 tokenId,
        uint256 value
    ) public view returns (uint256 amount) {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        IRuleset ruleset = _propertyInfoOf[tokenId].ruleset;
        if (address(ruleset) == address(0)) {
            amount = uint256(0);
        } else {
            amount = ruleset.getRoyaltyAmount(action, value);
        }
    }

    function getIngredients(uint256 tokenId)
        public
        view
        returns (uint256[] memory ids, uint256[] memory amounts)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        Property memory property = _propertyInfoOf[tokenId];
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
        if (!address(ruleset).supportsInterface(type(IRuleset).interfaceId)) {
            revert InvalidRule(ruleset);
        }
        if (address(metadata) == address(0)) {
            revert InvalidMetadata(metadata);
        }
        if (!metadataRegistry.isRegistered(metadata)) {
            revert NotRegisteredMetadata(metadata);
        }
        if (!metadata.exists(metadataId)) {
            revert InexistenceMetadata(metadata, metadataId);
        }

        uint256 tokenId = _tokenIdByMetadata[metadata][metadataId];

        if (exists(tokenId)) {
            revert AlreadyMinted(tokenId);
        }

        if (tokenId == uint256(0)) {
            tokenId = ++totalSupply;

            Property storage property = _propertyInfoOf[tokenId];
            property.creator = creator;
            property.ruleset = ruleset;
            property.metadata = metadata;
            property.metadataId = metadataId;

            _tokenIdByMetadata[metadata][metadataId] = tokenId;

            emit PropertyCreated(tokenId, property);
        }

        _payFee(
            configurator.feeToken(),
            msg.sender,
            configurator.treatury(),
            configurator.getFeeAmount(
                Action.CopyrightClaim,
                metadata,
                metadataId,
                1
            )
        );

        _safeMint(creator, tokenId);
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

        (IMetadata metadata, uint256 metadataId) = metadataOf(tokenId);

        _burn(tokenId);

        _payFee(
            configurator.feeToken(),
            msg.sender,
            configurator.treatury(),
            configurator.getFeeAmount(
                Action.CopyrightWaive,
                metadata,
                metadataId,
                1
            )
        );
    }

    function updateRule(uint256 tokenId, IRuleset ruleset) external {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        if (!address(ruleset).supportsInterface(type(IRuleset).interfaceId)) {
            revert InvalidRule(ruleset);
        }

        IRuleset propertyRule = _propertyInfoOf[tokenId].ruleset;
        if (propertyRule.isUpgradable()) {
            propertyRule = ruleset;
            emit PropertyRulesetUpdated(tokenId, ruleset);
        }
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
