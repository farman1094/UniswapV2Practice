// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;
import {IUniswapV2Pair} from "v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {UNISWAP_V2_PAIR_DAI_WETH} from "src/constants.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {UNISWAP_V2_FACTORY, WETH, DAI, MKR, UNISWAP_V2_ROUTER_02} from "src/constants.sol";
import{console} from "forge-std/console.sol";

contract FlashSwap2 {
    IUniswapV2Pair private immutable pair;
    address private immutable token0;
    address private immutable token1;

    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
    }
 
    function flashSwap(address token, uint256 amount) external {
    require(token == token0 || token == token1, "invalid token");

    // Write your code here

    // Don't change any other code

    // 1. Determine amount0Out and amount1Out
    uint256 amount0Out = token == token0 ? amount : 0;
    uint256 amount1Out = token == token1 ? amount : 0;

    // 2. Encode token and msg.sender as bytes
    bytes memory data = abi.encode(token, msg.sender);

    // 3. Call pair.swap
    pair.swap(
        amount0Out,
        amount1Out,
        address(this),
        data
    );
}

// Uniswap V2 callback
function uniswapV2Call(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
) external {

    // Write your code here

    // Don't change any other code

    // 1. Require msg.sender is pair contract
    require(msg.sender == address(pair), "Uniswap V2: INVALID_TO");

    // 2. Require sender is this contract
    require(sender == address(this), "Uniswap V2: INVALID_TO");


    // 3. Decode token and caller from data
    (address token, address caller) = abi.decode(data, (address, address));

    // 4. Determine amount borrowed (only one of them is > 0)
    uint256 amount = amount0 > amount1 ? amount0 : amount1;

    // 5. Calculate flash swap fee and amount to repay
    uint256 fee = (amount * 3) / 997 + 1; // 1 to round up
    uint256 amountToRepay = amount + fee;

    // 6. Get flash swap fee from caller
    IERC20(token).transferFrom(caller, address(this), amountToRepay);
    
    // 7. Repay Uniswap V2 pair
    IERC20(token).transfer(address(pair), amountToRepay);
}


}