// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {UNISWAP_V2_FACTORY, WETH, DAI, MKR, UNISWAP_V2_ROUTER_02 } from "src/constants.sol";
import {IWETH} from "src/interface/IWETH.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {FlashSwap} from "./FlashSwap.sol";

contract UniSwapV2Test is Test {

IUniswapV2Router02 public router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02); 
IUniswapV2Factory public factory = IUniswapV2Factory(UNISWAP_V2_FACTORY); 
IWETH public weth = IWETH(WETH);
IERC20 public dai = IERC20(DAI);
IERC20 public mkr = IERC20(MKR);
ERC20Mock public token;
address private constant user = address(100);

function setUp() public  {
    console.log(block.chainid);
    
    deal(user, 1000e18);
    assert(user.balance == 1000e18);
    vm.startPrank(user);
    weth.deposit{value: 1000 ether}();
    weth.approve(address(router), type(uint256).max);
    dai.approve(address(router), type(uint256).max);
    vm.stopPrank(); 
     token = new ERC20Mock();
}


function testFlashSwap() public {
    FlashSwap flashSwap = new FlashSwap();
    flashSwap.flashSwap(DAI, 100e18);

}


function testToAddLiquidityInDaiWethPoolAndRemove() public {
    console.log(weth.balanceOf(user));
    address pair = factory.getPair(DAI,WETH);
    console.log(pair);
    (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) =  IUniswapV2Pair(pair).getReserves();
    // function () external view returns (address);
    address token0 =  IUniswapV2Pair(pair).token0();
    if(token0 == DAI ) {
        console.log("DAIII");
    }else if( token0 == WETH){
        console.log("weht");
    }
    uint min = (reserve0 * 499) / reserve1; 
     address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = DAI;
    vm.startPrank(user);
    router.swapExactTokensForTokens(500e18, min, path, user, block.timestamp + 1000);
    (uint112 Afterreserve0, uint112 afterreserve1,) =  IUniswapV2Pair(pair).getReserves();

    uint wethBal = weth.balanceOf(user);
    uint daiBal = dai.balanceOf(user);

        // #OfWeth * currPrice ------------------------|
    (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(DAI, WETH, daiBal, wethBal, 1000000e18, wethBal, user, block.timestamp + 1000);

    console.log("after Bal weth", weth.balanceOf(user));
    console.log("after Bal dai", dai.balanceOf(user));
    console.log("shares bal", IUniswapV2Pair(pair).balanceOf(user));
    assert(0 < IUniswapV2Pair(pair).balanceOf(user));

    console.log("amount A", amountA);
    console.log("amount B", amountB);
    console.log("liquidity", liquidity);

    ////////////////////////////////////////
    //   REMOVE LIQUIDITY
    ////////////////////////////////////////
    IUniswapV2Pair(pair).approve(address(router), type(uint256).max);
       (uint redeemedAmountA, uint redeemedAmountB) = router.removeLiquidity(DAI, WETH, liquidity, 1000000e18, 499e18, user, block.timestamp + 1000);
    //    uint shareLeft = IUniswapV2Pair(pair).balanceOf(user);
       assertEq(redeemedAmountA, dai.balanceOf(user), "dai assertion failed");
       assertEq(redeemedAmountB, weth.balanceOf(user), "weth assertion failed");
    //    assertEq(0, shareLeft, "shares assertion failed");
    console.log("amount A", redeemedAmountA);
    console.log("amount B", redeemedAmountB);


    vm.stopPrank();
}


function testCreatePair() public {  
    address pair = factory.createPair(WETH, address(token));

        // address token0 = IUniswapV2Factory(pair).token0();
        // address token1 = IUniswapV2Factory(pair).token1();
        address actualPair = factory.getPair( address(token), WETH);
        assertEq(pair, actualPair, 'pair');   
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1(); 
        
        if (address(token) < WETH) {
          assertEq(token0, address(token), "token 0");
          assertEq(token1, WETH, "token 1");
        } else {
          assertEq(token0, WETH, "token 0");
          assertEq(token1, address(token), "token 1");
        }
}

        function testSwapExactTokensForTokens
        () public {
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

            console.log("amounts: WETH", amounts[0]);    
            console.log("amounts: DAI", amounts[1]);    
            console.log("amounts: MKR", amounts[2]);    
        }

        function testSwapTokensForExactTokens() public {
            address[] memory path = new address[](3);
            path[0] = WETH;
            path[1] = DAI;
            path[2] = MKR;
            uint deadline = block.timestamp + 1000;
            uint amountOut = 1e17;
            uint amountInMax = 1e18;
            vm.prank(user);
            uint[] memory amounts = router.swapTokensForExactTokens(
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