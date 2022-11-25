// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Property, Action} from "../../src/interfaces/Structs.sol";
import {IConfigurator} from "../../src/interfaces/IConfigurator.sol";
import {IMetadataRegistry} from "../../src/interfaces/IMetadataRegistry.sol";
import {ICopyright} from "../../src/interfaces/ICopyright.sol";
import {IMetadata} from "../../src/interfaces/IMetadata.sol";
import {IRuleset} from "../../src/interfaces/IRuleset.sol";
import {IERC165} from "../../src/interfaces/IERC165.sol";
import {IERC2981} from "../../src/interfaces/IERC2981.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {ERC721} from "../../src/libraries/ERC721.sol";

contract MockCopyright is ICopyright, ERC721("HiggsPixel Copyright", "HPCR") {
    /**
        Mock Copyright
     */
    IConfigurator public configurator;

    IMetadataRegistry public metadataRegistry;

    mapping(uint256 => Property) public _propertyInfoOf;

    function propertyInfoOf(uint256 tokenId)
        external
        view
        returns (Property memory property)
    {
        property = _propertyInfoOf[tokenId];
    }

    function metadataOf(uint256 tokenId)
        external
        view
        returns (IMetadata metadata, uint256 metadataId)
    {
        Property memory property = _propertyInfoOf[tokenId];
        metadata = property.metadata;
        metadataId = property.metadataId;
    }

    function setPropertyInfo(uint256 tokenId, Property memory property)
        external
    {
        _propertyInfoOf[tokenId] = property;
    }

    // mapping from owner to action to tokenId to amount to ok
    mapping(address => mapping(Action => mapping(uint256 => mapping(uint256 => bool))))
        public canDo;

    // mapping from action to tokenId to token
    mapping(Action => mapping(uint256 => IERC20)) public getRoyaltyToken;

    // mapping from action to tokenId to receiver
    mapping(Action => mapping(uint256 => address)) public getRoyaltyReceiver;

    // mapping from action to tokenId to value to amount
    mapping(Action => mapping(uint256 => mapping(uint256 => uint256)))
        public getRoyaltyAmount;

    function getIngredients(uint256 tokenId)
        external
        pure
        returns (uint256[] memory ids, uint256[] memory amounts)
    {
        if (tokenId == 1) {
            ids = new uint256[](0);
            amounts = new uint256[](0);
        } else {
            ids[0] = 1;
            amounts[0] = 1;
        }
    }

    // mapping from tokenId to ok
    mapping(uint256 => bool) public exists;

    // mapping from metadata to metadataId to tokenId;
    mapping(IMetadata => mapping(uint256 => uint256)) public search;

    function claim(
        address,
        IRuleset,
        IMetadata,
        uint256
    ) external pure {
        return;
    }

    function waive(uint256) external pure {
        return;
    }

    function updateRule(uint256, IRuleset) external pure {
        return;
    }

    function tokenURI(uint256)
        public
        pure
        override(ERC721)
        returns (string memory)
    {
        return "hello";
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

    function royaltyInfo(uint256, uint256)
        external
        pure
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(0);
        royaltyAmount = uint256(0);
    }
}
