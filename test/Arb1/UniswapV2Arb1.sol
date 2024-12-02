// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {console} from "forge-std/console.sol";


contract UniswapV2Arb1 {
    error ARB_IN_LOSS();
    struct SwapParams {
        // Router to execute first swap - tokenIn for tokenOut
        address router0;
        // Router to execute second swap - tokenOut for tokenIn
        address router1;
        // Token in of first swap
        address tokenIn;
        // Token out of first swap
        address tokenOut;
        // Amount in for the first swap
        uint256 amountIn;
        // Revert the arbitrage if profit is less than this minimum
        uint256 minProfit;
    }

    // Exercise 1
    // - Execute an arbitrage between router0 and router1
    // - Pull tokenIn from msg.sender
    // - Send amountIn + profit back to msg.sender
    function swap(SwapParams calldata params) external {
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        uint amountOut = _swap(params);
        require(amountOut - params.amountIn >= params.minProfit, "In Loss");
        IERC20(params.tokenIn).transfer(msg.sender, amountOut);        
        // Write your code here
        // Don’t change any other code
    }

    // Exercise 2
    // - Execute an arbitrage between router0 and router1 using flash swap
    // - Borrow tokenIn with flash swap from pair
    // - Send profit back to msg.sender
    /**
     * @param pair Address of pair contract to flash swap and borrow tokenIn
     * @param isToken0 True if token to borrow is token0 of pair
     * @param params Swap parameters
     */
    function flashSwap(address pair, bool isToken0, SwapParams calldata params)
        external
    {
        uint amount0Out; 
        uint amount1Out; 
        if(isToken0){
            amount0Out = params.amountIn;
        } else {
            amount1Out = params.amountIn;
        }
        /**swap(uint amount0Out, uint amount1Out, address to, bytes calldata data)  */
        bytes memory data = abi.encode(msg.sender, pair, params);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
        // Write your code here
        // Don’t change any other code
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external {

        (address initiator, address pair, SwapParams memory params) = abi.decode(data, (address, address, SwapParams ));
        require(msg.sender == pair, "Unauthorized");
        uint amountOut = _swap( params );

        uint  fee = (params.amountIn * 3) / 997 + 1; // 1 to round up
        uint amountToRepay = params.amountIn + fee;

        require(amountOut > (amountToRepay + params.minProfit),  "In Loss");
        IERC20(params.tokenIn).transfer(msg.sender, amountToRepay);
        IERC20(params.tokenIn).transfer(initiator, (amountOut - amountToRepay));

        // Write your code here
        // Don’t change any other code
    }

    function _swap(SwapParams memory params) internal returns (uint256 amountOut) {
        // aprroves router0 and route1 to spend tokenIn

        // swap to route0
        IERC20(params.tokenIn).approve(params.router0, params.amountIn);
        address[] memory pathRoute0 = new address[](2);
        pathRoute0[0] = params.tokenIn;
        pathRoute0[1] = params.tokenOut;
       uint[] memory amounts = IUniswapV2Router02(params.router0).swapExactTokensForTokens(
            params.amountIn,
            1,
            pathRoute0,
            address(this),
            block.timestamp
        );


        // swap to route1
        uint newBal = IERC20(params.tokenOut).balanceOf(address(this));
        IERC20(params.tokenOut).approve(params.router1, amounts[1]);
        address[] memory pathRoute1 = new address[](2);
        pathRoute1[0] = params.tokenOut;
        pathRoute1[1] = params.tokenIn;
        IUniswapV2Router02(params.router1).swapExactTokensForTokens(
            newBal,
            1,
            pathRoute1,
            address(this),
            block.timestamp
        );
         amountOut = IERC20(params.tokenIn).balanceOf(address(this));
    }
}