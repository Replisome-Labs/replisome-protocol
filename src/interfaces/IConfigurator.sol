// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "./IERC20.sol";
import {INFTRenderer} from "./INFTRenderer.sol";
import {IFeeFormula} from "./IFeeFormula.sol";
import {IMetadata} from "./IMetadata.sol";

enum Action {
    CopyrightClaim,
    CopyrightWaive,
    CopyrightSale,
    ArtworkCopy,
    ArtworkBurn,
    ArtworkUtilize
}

interface IConfigurator {
    /**
     * @dev Emits when the treasury is set
     */
    event TreasuryUpdated(address indexed vault);

    /**
     * @dev Emits when the feeToken is set
     */
    event FeeTokenUpdated(IERC20 indexed token);

    /**
     * @dev Emits when the `feeFormula` of the `action` is set
     */
    event FeeUpdated(Action indexed action, IFeeFormula indexed feeFormula);

    /**
     * @dev Emits when the copyright `renderer` is set
     */
    event CopyrightRendererUpdated(INFTRenderer indexed renderer);

    /**
     * @dev Returns treasury address
     */
    function treasury() external view returns (address vault);

    /**
     * @dev set address of the treasury
     * Emits a {TreasuryUpdated} event
     */
    function setTreasury(address vault) external;

    /**
     * @dev Returns feeToken
     */
    function feeToken() external view returns (IERC20 token);

    /**
     * @dev set address of the feeToken
     * Emits a {FeeTokenUpdated} event
     */
    function setFeeToken(IERC20 token) external;

    /**
     * @dev Returns fee price that is computed by `action`, `metadata`, `metadataId`, and `amount`
     */
    function getFeeAmount(
        Action action,
        IMetadata metadata,
        uint256 metadataId,
        uint256 amount
    ) external view returns (uint256 price);

    /**
     * @dev set `feeFormula` of the `action`
     * Emits a {FeeUpdated} event
     */
    function setFeeFormula(Action action, IFeeFormula feeFormula) external;

    /**
     * @dev Returns the address of copyright renderer
     */
    function copyrightRenderer() external view returns (INFTRenderer renderer);

    /**
     * @dev set copyright renderer
     * Emits a {CopyrightRendererUpdated} event
     */
    function setCopyrightRenderer(INFTRenderer renderer) external;
}
