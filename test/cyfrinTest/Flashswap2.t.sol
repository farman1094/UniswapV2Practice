// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;
import {Test} from "forge-std/Test.sol";
import {IUniswapV2Pair} from "v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {UNISWAP_V2_PAIR_DAI_WETH} from "src/constants.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {UNISWAP_V2_FACTORY, WETH, DAI, MKR, UNISWAP_V2_ROUTER_02} from "src/constants.sol";
import {FlashSwap2} from "test/cyfrinTest/FlashSwap2.sol";
import {IWETH} from "src/interface/IWETH.sol";
import {console} from "forge-std/console.sol";

// UniswapRouter02 private constant router = UniswapRouter02(UNISWAP_V2_ROUTER_02);
contract FlashSwapTest is Test {
FlashSwap2 public flashSwap;
IWETH public weth = IWETH(WETH);
IERC20 public dai = IERC20(DAI);
IERC20 public mkr = IERC20(MKR);

address private constant user = address(100);

function setUp() public {
    flashSwap = new FlashSwap2(UNISWAP_V2_PAIR_DAI_WETH);
}

function testFlashSwap() public {
    uint256 dai0 = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);
    vm.startPrank(user);
    deal(DAI, user, 10000 * 1e18);
    dai.approve(address(flashSwap), type(uint256).max);
   

    // user -> pair.swap
    // -> flashSwap.uniswapV2Call
    // -> token.transferFrom(user, flashSwap, fee)

    flashSwap.flashSwap(DAI, 1e18);

    uint256 dai1 = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);

    console.log("DAI (fee):",  dai1 - dai0);

    assertGt(dai1, dai0, "DAI balance of pair");
    vm.stopPrank();
}
}