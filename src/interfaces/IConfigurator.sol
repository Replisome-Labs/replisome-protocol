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
    event TreaturyUpdated(address indexed vault);

    event FeeTokenUpdated(IERC20 indexed token);

    event FeeUpdated(Action indexed action, IFeeFormula indexed feeFormula);

    event CopyrightRendererUpdated(INFTRenderer indexed renderer);

    function treatury() external view returns (address vault);

    function setTreatury(address vault) external;

    function feeToken() external view returns (IERC20 token);

    function setFeeToken(IERC20 token) external;

    function getFeeAmount(
        Action action,
        IMetadata metadata,
        uint256 metadataId,
        uint256 amount
    ) external view returns (uint256 price);

    function setFeeFormula(Action action, IFeeFormula feeFormula) external;

    function copyrightRenderer() external view returns (INFTRenderer renderer);

    function setCopyrightRenderer(INFTRenderer renderer) external;
}
