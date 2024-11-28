// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {WETH, DAI, MKR, UNISWAP_V2_ROUTER_02 } from "src/constants.sol";
import {IWETH} from "src/interface/IWETH.sol";

contract UniSwapV2SwapTest is Test {

IUniswapV2Router02 public router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
IWETH public weth = IWETH(WETH);
IERC20 public dai = IERC20(DAI);
IERC20 public mkr = IERC20(MKR);

address private constant user = address(100);

function setUp() public  {
    console.log(block.chainid);
    deal(user, 100e18);
    console.log(user.balance);
    vm.startPrank(user);
    weth.deposit{value: 100 ether}();
    weth.approve(address(router), type(uint256).max);
    
    vm.stopPrank(); 
}
        function testSwapExactTokensForTokens() public {
            uint amountIn = 1e18;
            uint amountOutMin = 1;
            address[] memory path = new address[](3);
            path[0] = address(weth);
            path[1] = address(dai);
            path[2] = address(mkr);
            uint deadline = block.timestamp + 1000;

            uint[] memory amounts = router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                user,
                deadline
            );

            console.log("amounts: %s", amounts[0]);    

        }
}