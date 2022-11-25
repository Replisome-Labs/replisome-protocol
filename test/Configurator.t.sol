// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Configurator} from "../src/Configurator.sol";
import {Unauthorized} from "../src/interfaces/Errors.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {ICopyrightRenderer} from "../src/interfaces/ICopyrightRenderer.sol";

contract ConfiguratorTest is Test {
    event TreaturyUpdated(address indexed vault);

    event FeeTokenUpdated(IERC20 indexed token);

    event CopyrightRendererUpdated(ICopyrightRenderer indexed renderer);

    Configurator public configurator;

    address public constant prankAddress = address(0);
    address public constant treatury = address(100);
    IERC20 public constant feeToken = IERC20(address(200));
    uint256 public constant copyrightClaimFee = uint256(300);
    uint256 public constant copyrightWaiveFee = uint256(400);
    uint256 public constant artworkCopyFee = uint256(500);
    uint256 public constant artworkBurnFee = uint256(600);
    ICopyrightRenderer public constant copyrightRenderer =
        ICopyrightRenderer(address(700));

    function setUp() public {
        configurator = new Configurator();
    }

    function testSetTreatury() public {
        vm.expectEmit(true, false, false, false);
        emit TreaturyUpdated(treatury);
        configurator.setTreatury(treatury);
        assertEq(configurator.treatury(), treatury);
    }

    function testSetTreaturyAsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(Unauthorized.selector, prankAddress)
        );
        vm.startPrank(prankAddress);
        configurator.setTreatury(treatury);
        vm.stopPrank();
    }

    function testSetFeeToken() public {
        vm.expectEmit(true, false, false, false);
        emit FeeTokenUpdated(feeToken);
        configurator.setFeeToken(feeToken);
        assertEq(address(configurator.feeToken()), address(feeToken));
    }

    function testSetFeeTokenAsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(Unauthorized.selector, prankAddress)
        );
        vm.startPrank(prankAddress);
        configurator.setFeeToken(feeToken);
        vm.stopPrank();
    }

    function testSetCopyrightRenderer() public {
        vm.expectEmit(true, false, false, false);
        emit CopyrightRendererUpdated(copyrightRenderer);
        configurator.setCopyrightRenderer(copyrightRenderer);
        assertEq(
            address(configurator.copyrightRenderer()),
            address(copyrightRenderer)
        );
    }

    function testSetCopyrightRendererAsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(Unauthorized.selector, prankAddress)
        );
        vm.startPrank(prankAddress);
        configurator.setCopyrightRenderer(copyrightRenderer);
        vm.stopPrank();
    }
}
