// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {WETH, DAI, MKR, UNISWAP_V2_ROUTER_02 } from "src/constants.sol";
import {IWETH} from "src/interface/IWETH.sol";

contract IssueInTest is Test {

IUniswapV2Router02 public router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
IWETH public weth = IWETH(WETH);
IERC20 public dai = IERC20(DAI);
IERC20 public mkr = IERC20(MKR);

address private constant user = address(100);

function setUp() public  {
    console.log(block.chainid);
    
    deal(user, 100e18);
    assert(user.balance == 100e18);
    vm.startPrank(user);
    weth.deposit{value: 100 ether}();
    weth.approve(address(router), type(uint256).max);
    vm.stopPrank(); 
    
    // 
}
        function testSwapExactTokensForIssues() public {
            address[] memory path = new address[](3);
            path[0] = WETH;
            path[1] = DAI;
            path[2] = MKR;
            uint deadline = block.timestamp + 1000;
            uint amountIn = 1e18;
            uint amountOutMin = 1;

            vm.prank(user);
            uint[] memory amounts = router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                user,
                deadline
            );

            uint amountOut = 1e17;
            uint amountInMax = 50e18;
            vm.prank(user);
            uint[] memory amountsOut = router.swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                user,
                deadline
            );

            console.log("amounts: WETH", amounts[0]);    
            console.log("amounts: DAI", amounts[1]);    
            console.log("amounts: MKR", amounts[2]);    
        }
}


/* @NOTE Working in this order

        function testSwapExactTokensForIssues() public {
            address[] memory path = new address[](3);
            path[0] = WETH;
            path[1] = DAI;
            path[2] = MKR;
            uint deadline = block.timestamp + 1000;
            uint amountIn = 1e18;
            uint amountOutMin = 1;


            uint amountOut = 1e17;
            uint amountInMax = 50e18;
            vm.prank(user);
            uint[] memory amountsOut = router.swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                user,
                deadline
            );


            vm.prank(user);
            uint[] memory amounts = router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                user,
                deadline
            );
*/