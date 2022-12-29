// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMetadata} from "../../src/interfaces/IMetadata.sol";
import {ICopyright} from "../../src/interfaces/ICopyright.sol";
import {IERC165} from "../../src/interfaces/IERC165.sol";
import {ERC165} from "../../src/libraries/ERC165.sol";
import {Strings} from "../../src/libraries/Strings.sol";

contract MockMetadata is IMetadata, ERC165 {
    using Strings for uint256;

    ICopyright public copyright;

    uint256 public totalSupply;

    mapping(bytes => uint256) public dataToId;
    mapping(uint256 => bytes) public idToData;

    function generateHTML(uint256 metadataId)
        external
        pure
        returns (string memory svg)
    {
        svg = metadataId.toString();
    }

    function generateRawData(uint256 metadataId)
        external
        view
        returns (bytes memory raw)
    {
        raw = idToData[metadataId];
    }

    mapping(IMetadata => bool) public supportsMetadata;

    mapping(uint256 => bool) public exists;

    mapping(uint256 => uint256) public width;

    mapping(uint256 => uint256) public height;

    mapping(uint256 => bytes4[]) public _getColors;

    function getColors(uint256 metadataId)
        external
        view
        returns (bytes4[] memory colors)
    {
        colors = _getColors[metadataId];
    }

    mapping(uint256 => uint256[]) public getIngredientIds;

    mapping(uint256 => uint256[]) public getIngredientAmounts;

    function getIngredients(uint256 metadataId)
        external
        view
        returns (uint256[] memory ids, uint256[] memory amounts)
    {
        ids = getIngredientIds[metadataId];
        amounts = getIngredientAmounts[metadataId];
    }

    function verify(bytes calldata data)
        external
        view
        returns (uint256 metadataId)
    {
        metadataId = dataToId[data];
    }

    function create(bytes calldata data) external returns (uint256 metadataId) {
        metadataId = ++totalSupply;
        dataToId[data] = metadataId;
        idToData[metadataId] = data;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IMetadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
