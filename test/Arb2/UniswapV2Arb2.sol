// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IUniswapV2Pair} from "v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract UniswapV2Arb2 {
    struct FlashSwapData {
        // Caller of flashSwap (msg.sender inside flashSwap)
        address caller;
        // Pair to flash swap from
        address pair0;
        // Pair to swap from
        address pair1;
        // True if flash swap is token0 in and token1 out
        bool isZeroForOne;
        // Amount in to repay flash swap
        uint256 amountIn;
        // Amount to borrow from flash swap
        uint256 amountOut;
        // Revert if profit is less than this minimum
        uint256 minProfit;
    }

    // Exercise 1
    // - Flash swap to borrow tokenOut
    /**
     * @param pair0 Pair contract to flash swap
     * @param pair1 Pair contract to swap
     * @param isZeroForOne True if flash swap is token0 in and token1 out
     * @param amountIn Amount in to repay flash swap
     * @param minProfit Minimum profit that this arbitrage must make
     */
    function flashSwap(
        address pair0,
        address pair1,
        bool isZeroForOne,
        uint256 amountIn,
        uint256 minProfit
    ) external {
        /**    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock { */
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair0).getReserves();
        (uint reserveIn, uint reserveOut) = isZeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
        // (uint reserveIn, uint reserveOut) = isZeroForOne ? (amountIn, 0) : (0, amountIn);
        uint amountOut = getAmountOut(amountIn, reserveIn, reserveOut);

       FlashSwapData memory params = FlashSwapData ({
        caller: msg.sender,
        pair0: pair0,
        pair1:pair1,
        isZeroForOne: isZeroForOne,
        amountIn: amountIn,
        amountOut: amountOut,
        minProfit:  minProfit
    });
        bytes memory data = abi.encode(params); 

        IUniswapV2Pair(pair0).swap({
            amount0Out: isZeroForOne ? 0 : amountOut,
            amount1Out: isZeroForOne ? amountOut : 0,
            to: address(this),
            data: data
        });
        // Write your code here
        // Don’t change any other code

        // Hint - use getAmountOut to calculate amountOut to borrow
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external {
        FlashSwapData memory params = abi.decode(data,(FlashSwapData));

        address token0 = IUniswapV2Pair(params.pair1).token0();
        address token1 = IUniswapV2Pair(params.pair1).token1();

        address tokenIn = params.isZeroForOne ? token0 : token1;
        address tokenOut = params.isZeroForOne ? token1 : token0;

         (uint reserve0, uint reserve1,) = IUniswapV2Pair(params.pair1).getReserves();
        // (uint reserveIn, uint reserveOut) = isZeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
         
         uint amountOut = params.isZeroForOne ?  getAmountOut(params.amountOut, reserve1, reserve0) : getAmountOut(params.amountOut, reserve0, reserve1);
        require(amountOut > (params.amountIn + params.minProfit), "Arb In Loss");
        IERC20(tokenOut).transfer(params.pair1, params.amountOut);
        IUniswapV2Pair(params.pair1).swap({
            amount0Out: params.isZeroForOne ? amountOut : 0,
            amount1Out: params.isZeroForOne ? 0 : amountOut,
            to: address(this),
            data: ""
        });
        IERC20(tokenIn).transfer(params.pair0, params.amountIn);
        IERC20(tokenIn).transfer(params.caller, (amountOut - params.amountIn));



        // Write your code here
        // Don’t change any other code
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}