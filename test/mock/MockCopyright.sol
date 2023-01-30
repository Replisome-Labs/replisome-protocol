// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IConfigurator, Action} from "../../src/interfaces/IConfigurator.sol";
import {IMetadataRegistry} from "../../src/interfaces/IMetadataRegistry.sol";
import {ICopyright, Property} from "../../src/interfaces/ICopyright.sol";
import {IArtwork} from "../../src/interfaces/IArtwork.sol";
import {IMetadata} from "../../src/interfaces/IMetadata.sol";
import {IRuleset} from "../../src/interfaces/IRuleset.sol";
import {IERC165} from "../../src/interfaces/IERC165.sol";
import {IERC2981} from "../../src/interfaces/IERC2981.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {IERC721} from "../../src/interfaces/IERC721.sol";
import {IERC721Metadata} from "../../src/interfaces/IERC721Metadata.sol";
import {NotMinted} from "../../src/interfaces/Errors.sol";
import {ERC721} from "../../src/libraries/ERC721.sol";

contract MockCopyright is ICopyright, ERC721("Replisome Copyright", "RPS-CR") {
    /**
        Mock Copyright
     */
    IConfigurator public configurator;

    IMetadataRegistry public metadataRegistry;

    IArtwork public artwork;

    uint256 public totalSupply;

    mapping(uint256 => address) public testOwnerOf;

    function ownerOf(uint256 id)
        public
        view
        override(ERC721, IERC721)
        returns (address owner)
    {
        owner = testOwnerOf[id];
        if (owner == address(0)) {
            revert NotMinted(id);
        }
    }

    mapping(uint256 => IMetadata) public _metadataContractOf;

    mapping(uint256 => uint256) public _metadataIdOf;

    function metadataOf(uint256 tokenId)
        external
        view
        returns (IMetadata metadata, uint256 metadataId)
    {
        metadata = _metadataContractOf[tokenId];
        metadataId = _metadataIdOf[tokenId];
    }

    mapping(uint256 => address) public _creatorOf;

    function creatorOf(uint256 tokenId)
        external
        view
        returns (address creator)
    {
        creator = _creatorOf[tokenId];
    }

    mapping(uint256 => IRuleset) public _rulesetOf;

    function rulesetOf(uint256 tokenId)
        external
        view
        returns (IRuleset ruleset)
    {
        ruleset = _rulesetOf[tokenId];
    }

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

    function updateRuleset(uint256, IRuleset) external pure {
        return;
    }

    function tokenURI(uint256)
        public
        pure
        override(IERC721Metadata, ERC721)
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
