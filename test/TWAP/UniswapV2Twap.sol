// SPDX-License-Identifier: MIT
pragma solidity >= 0.4 < 0.9;
import {IUniswapV2Pair} from "v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {FixedPoint} from "src/libraries/FixedPoint.sol";

// Modified from https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
// Do not use this contract in production
contract UniswapV2Twap {
    using FixedPoint for *;

    // Minimum wait time in seconds before the function update can be called again
    // TWAP of time > MIN_WAIT
    uint256 private constant MIN_WAIT = 300;

    IUniswapV2Pair public immutable pair;
    address public immutable token0;
    address public immutable token1;

    // Cumulative prices are uq112x112 price * seconds
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    // Last timestamp the cumulative prices were updated
    uint32 public updatedAt;

    // TWAP of token0 and token1
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    // TWAP of token0 in terms of token1
    FixedPoint.uq112x112 public price0Avg;
    // TWAP of token1 in terms of token0
    FixedPoint.uq112x112 public price1Avg;

    // Exercise 1
    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);

        token0 = pair.token0();
        token1  = pair.token1();
        
        // 3. Store price0CumulativeLast and price1CumulativeLast from pair contract
        price0CumulativeLast = pair.price0CumulativeLast();
        price1CumulativeLast = pair.price1CumulativeLast();

        // 4. Call pair.getReserve to get last timestamp the reserves were updated
        //    and store it into the state variable updatedAt
        (, ,  updatedAt) = pair.getReserves();
    }

    // Exercise 2
    // Calculates cumulative prices up to current timestamp
    function _getCurrentCumulativePrices()
        internal
        view
        returns (uint256 price0Cumulative, uint256 price1Cumulative)
    {

        // If current block timestamp > last timestamp reserves were updated,
        // calculate cumulative prices until current time.
        // Otherwise return latest cumulative prices retrieved from the pair contract.
        
        // 1. Get latest cumulative prices from the pair contract        
           price0Cumulative =  pair.price0CumulativeLast();
           price1Cumulative =  pair.price1CumulativeLast();

        // 2. Get reserves and last timestamp the reserves were updated from the pair contract
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        // 3. Cast block.timestamp to uint32
        uint32 blockTimestamp = uint32(block.timestamp);

        if (blockTimestampLast != blockTimestamp) {
            // 4. Calculate elapsed time
            uint32 dt = blockTimestamp - blockTimestampLast;
            // Addition overflow is desired
            unchecked {
                // 5. Add spot price * elapsed time to cumulative prices.
                //    - Use FixedPoint.fraction to calculate spot price.
                        //  uint spotPrice0 =
                        //  uint spotPrice1 = reserve0.fraction(reserve1);
                //    - FixedPoint.fraction returns UQ112x112, so cast it into uint256.
                    // uint144 spotPrice0144 = spotPrice0.decode144();
                    // uint144 spotPric10144 = spotPrice1.decode144();
                //    - Multiply spot price by time elapsed
            //      price0Cumulative +=   uint((reserve1.fraction(reserve0).mul(dt)).decode144()) * dt;
                // price1Cumulative +=  uint((reserve0.fraction(reserve1).mul(dt)).decode144()) * dt;
                    price0Cumulative += uint256(FixedPoint.fraction(reserve1,reserve0)._x) * dt;
                    price1Cumulative += uint256(FixedPoint.fraction(reserve0,reserve1)._x) * dt;
            }
        } 
    }

    // Exercise 3
    // Updates cumulative prices
    function update() external {
        // 1. Cast block.timestamp to uint32
        uint32 blockTimestamp = uint32(block.timestamp);
        // 2. Calculate elapsed time since last time cumulative prices were
        //    updated in this contract
        uint32 dt = blockTimestamp - updatedAt;
        // 3. Require time elapsed >= MIN_WAIT
            require(dt > MIN_WAIT, "Wait for at least 300 sec");
        // 4. Call the internal function _getCurrentCumulativePrices to get
        //    current cumulative prices
        (uint256 price0Cumulative , uint256 price1Cumulative) = _getCurrentCumulativePrices();

        // Overflow is desired, casting never truncates
        // https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/building-an-oracle
        // Subtracting between two cumulative price values will result in
        // a number that fits within the range of uint256 as long as the
        // observations are made for periods of max 2^32 seconds, or ~136 years
        unchecked {
            // 5. Calculate TWAP price0Avg and price1Avg
            //    - TWAP = (current cumulative price - last cumulative price) / dt
            uint224 twap0 = uint224((price0Cumulative - price0CumulativeLast) / dt);
            uint224 twap1 = uint224((price1Cumulative - price1CumulativeLast) / dt);

            //    - Cast TWAP into uint224 and then into FixedPoint.uq112x112
            price0Avg = FixedPoint.uq112x112(twap0);
            price1Avg = FixedPoint.uq112x112(twap1);
        }

        // 6. Update state variables price0CumulativeLast, price1CumulativeLast and updatedAt
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        updatedAt = blockTimestamp;
    }

    // Exercise 4
    // Returns the amount out corresponding to the amount in for a given token
    function consult(address tokenIn, uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        // 1. Require tokenIn is either token0 or token1
        require(tokenIn == token0 || tokenIn == token1, "Invalid token");


        // 2. Calculate amountOut
        //    - amountOut = TWAP of tokenIn * amountIn
        //    - Use FixePoint.mul to multiply TWAP of tokenIn with amountIn
        //    - FixedPoint.mul returns uq144x112, use FixedPoint.decode144 to return uint144
        
        if (tokenIn == token0) {
            // Example
            //   token0 = WETH
            //   token1 = USDC
            //   price0Avg = avg price of WETH in terms of USDC = 2000 USDC / 1 WETH
            //   tokenIn = WETH
            //   amountIn = 2
            //   amountOut = price0Avg * amountIn = 4000 USDC
            // (price0Avg.mul(dt)).decode144()
            uint amountOut144 = uint((price0Avg.mul(amountIn)).decode144());
            amountOut = amountOut144;
        } else {
            //    uint144 amountOut144 = (price1Avg.mul(amountIn)).decode144();
               uint amountOut144 = uint((price1Avg.mul(amountIn)).decode144());
            amountOut = amountOut144;
        }
        return amountOut;
    }
}