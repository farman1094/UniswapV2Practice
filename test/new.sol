// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import { Test } from 'forge-std/Test.sol';
import {console} from "forge-std/console.sol";

import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { DAI, MKR, UNISWAP_V2_ROUTER_02 } from "src/constants.sol";
import { WETH } from "src/constants.sol";
import {IWETH} from "src/interface/IWETH.sol";


contract UniswapV2SwapTest is Test {
    IUniswapV2Router02 private constant router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant mkr = IERC20(MKR);
    address private constant user = address(100);


    function setUp() public {
    deal(user, 100 * 1e18);
    vm.startPrank(user);
    assert(user.balance == 100e18);
    console.log("user balance", user.balance);
    weth.deposit{value: 100 ether}();
    weth.approve(address(router), type(uint256).max);
    vm.stopPrank();
}


function testSwapExactTokensForTokedans() public {
    address[] memory path = new address[](3);
    path[0] = WETH;
    path[1] = DAI;
    path[2] = MKR;
    uint amountIn = 1e18;
    uint amountOutMin = 1;
    vm.startPrank(user);
    uint[] memory amounts = router.swapExactTokensForTokens(
        amountIn,
        amountOutMin,
        path,
        user,
        block.timestamp + 1000
    );
   console.log("amounts WETH", amounts[0]);
    console.log("amounts DAI", amounts[1]);
    console.log("amounts MKR", amounts[2]);
    assertGe(mkr.balanceOf(user), amountOutMin, "MKR balance of user");

    // uint amountOut = 1e18;
    // uint amountInMax = 1e18;
    //   uint[] memory amountsOut = router.swapTokensForExactTokens(
    //     amountOut,
    //     amountInMax,
    //     path,
    //     user,
    //     block.timestamp + 1000
    // );

    //  console.log("amounts WETH", amountsOut[0]);
    // console.log("amounts DAI", amountsOut[1]);
    // console.log("amounts MKR", amountsOut [2]);
    // assert(mkr.balanceOf(user) == amountOut);
    // vm.stopPrank();
}
}