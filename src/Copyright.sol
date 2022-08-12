// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Property} from "./interfaces/Structs.sol";
import {AlreadyMinted, NotMinted, InvalidRule, InvalidMetadata, InvalidLayer, NotRegisteredMetadata} from "./interfaces/Errors.sol";
import {ICopyright} from "./interfaces/ICopyright.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {ERC721} from "./libraries/ERC721.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {ERC165Checker} from "./libraries/ERC165Checker.sol";

contract Copyright is ICopyright, ERC721("HiggsPixel Copyright", "HPCR") {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    IConfigurator public immutable configurator;

    IMetadataRegistry public immutable metadataRegistry;

    uint256 public totalSupply;

    // mapping from tokenId to Property
    mapping(uint256 => Property) public propertyInfoOf;

    // mapping from tokenId to ingredientId to amount
    mapping(uint256 => mapping(uint256 => uint256)) public ingredientAmountOf;

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
        override(ERC165, IERC165, IERC721)
        returns (bool)
    {
        return
            interfaceId == type(ICopyright).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = copyright.getRoyaltyToken(tokenId, ActionType.CopyrightSale);
        royaltyAmount = copyright.getRoyaltyAmount(
            tokenId,
            ActionType.CopyrightSale,
            salePrice
        );
    }

    function tokenURI(uint256 id) public view virtual returns (string memory) {
        return "hello";
    }

    function canDo(
        address owner,
        ActionType action,
        uint256 tokenId,
        uint256 amount
    ) external view returns (bool ok) {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        IRule rule = propertyInfoOf[tokenId].rule;
        if (address(rule) == address(0)) {
            // All permission is open if rule is empty
            ok = true;
        }
        if (action == ActionType.Transfer) {
            ok = rule.canTransfer(owner, amount);
        }
        if (action == ActionType.Copy) {
            ok = rule.canCopy(owner, amount);
        }
        if (action == ActionType.Burn) {
            ok = rule.canBurn(owner, amount);
        }
    }

    function getRoyaltyToken(ActionType action, uint256 tokenId)
        external
        view
        returns (IERC20 token)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        IRule rule = propertyInfoOf[tokenId].rule;
        if (address(rule) == address(0)) {
            token = IERC20(address(0));
        } else {
            token = rule.getRoyaltyToken(action);
        }
    }

    function getRoyaltyReceiver(ActionType action, uint256 tokenId)
        external
        view
        returns (address receiver)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        IRule rule = propertyInfoOf[tokenId].rule;
        if (address(rule) == address(0)) {
            receiver = address(0);
        } else {
            receiver = rule.getRoyaltyReceiver(action);
        }
    }

    function getRoyaltyAmount(
        ActionType action,
        uint256 tokenId,
        uint256 value
    ) external view returns (uint256 amount) {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        IRule rule = propertyInfoOf[tokenId].rule;
        if (address(rule) == address(0)) {
            receiver = uint256(0);
        } else {
            receiver = rule.getRoyaltyAmount(action, value);
        }
    }

    function getIngredients(uint256 tokenId)
        external
        view
        returns (uint256[] ids, uint256[] amounts)
    {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        uint256[] memory ids = propertyInfoOf[tokenId].ingredients;
        uint256[] memory amounts = new uint256[](ids.length);
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                amounts[i] = ingredientAmountOf[tokenId][ids[i]];
            }
        }
    }

    function exists(uint256 tokenId) public view returns (bool ok) {
        ok = _ownerOf[tokenId] != address(0);
    }

    function search(IMetadata metadata, uint256 metadataId)
        external
        view
        returns (uint256 tokenId)
    {
        tokenId = _tokenIdByMetadata[metadata][metadataId];
    }

    function claim(
        address creator,
        IRule rule,
        IMetadata metadata,
        Layer[] memory layers,
        bytes calldata drawings
    ) external {
        if (!address(rule).supportsInterface(type(IRule).interfaceId)) {
            revert InvalidRule(rule);
        }
        if (address(metadata) == address(0)) {
            revert InvalidMetadata(metadata);
        }
        if (!metadataRegistry.isRegisterd(metadata)) {
            revert NotRegisteredMetadata(metadata);
        }

        uint256 metadataId = metadata.create(layers, drawings);
        uint256 tokenId = _tokenIdByMetadata[metadata][metadataId];

        if (exists(tokenId)) {
            revert AlreadyMinted(tokenId);
        }

        if (tokenId == uint256(0)) {
            tokenId = ++totalSupply;

            Property storage property = propertyInfoOf[tokenId];
            property.creator = creator;
            property.rule = rule;
            property.metadata = metadata;
            property.metadataId = metadataId;

            mapping(uint256 => uint256)
                storage tokenIngredientAmount = ingredientAmountOf[tokenId];
            unchecked {
                for (uint256 i = 0; i < layers.length; i++) {
                    Layer memory layer = layers[i];
                    uint256 ingredientId = _tokenIdByMetadata[layer.metadata][
                        layer.metadataId
                    ];
                    if (ingredientId == uint256(0)) {
                        revert InvalidLayer(layer);
                    }
                    if (tokenIngredientAmount[ingredientId] == uint256(0)) {
                        property.ingredients.push(ingredientId);
                    }
                    tokenIngredientAmount[ingredientId]++;
                }
            }

            _tokenIdByMetadata[metadata][metadataId] = tokenId;

            emit PropertyCreated(tokenId, property);
        }

        _safeMint(msg.sender, tokenId);
    }

    function waive(uint256 tokenId) external {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        if (
            msg.sender != from &&
            !isApprovedForAll[from][msg.sender] &&
            msg.sender != getApproved[id]
        ) {
            revert Unauthorized(msg.sender);
        }

        _burn(tokenId);
    }

    function updateRule(uint256 tokenId, IRule rule) external {
        if (!exists(tokenId)) {
            revert NotMinted(tokenId);
        }
        if (!address(rule).supportsInterface(type(IRule).interfaceId)) {
            revert InvalidRule(rule);
        }

        IRule storage propertyRule = propertyInfoOf[tokenId].rule;
        if (propertyRule.isUpgradable()) {
            propertyRule = rule;
            emit PropertyRuleUpdated(tokenId, rule);
        }
    }
}
