// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;
import {IUniswapV2Pair} from "v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {UNISWAP_V2_PAIR_DAI_WETH} from "src/constants.sol";
import {IERC20} from "lib/forge-std/src/interfaces/IERC20.sol";
import {UNISWAP_V2_FACTORY, WETH, DAI, MKR, UNISWAP_V2_ROUTER_02 } from "src/constants.sol";


 contract FlashSwap {

    IUniswapV2Pair public pair = IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_WETH);
    address public token0;
    address public token1;

    constructor() {
        token0 = pair.token0();
        token1 = pair.token1();
    }

    function flashSwap(address token, uint amount) external {
    require(token == token0 || token == token1, "invalid token");
    // encoding
    uint amount0 = token == token0 ? amount : 0;    
    uint amount1 = token == token1 ? amount : 0;
   // encoding
    bytes memory dataToSend = abi.encode(token, amount, address(this));

        pair.swap(amount0, amount1, address(this), dataToSend); 
    }

    // Uniswap V2 callback
function uniswapV2Call(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
) external {
    (address token, uint amountOut, ) = abi.decode(data, (address, uint, address));
    require(msg.sender == address(pair), 'Mandatory check failed');
    // decoding
    require( sender == address(this), 'Mandatory check failed');


    
      uint  fee = (amountOut * 3) / 997 + 1; // 1 to round up
    uint amountToRepay = amountOut + fee;
 

    IERC20(token).transfer(address(pair), amountToRepay);
}

}