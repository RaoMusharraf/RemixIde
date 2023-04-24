// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;


import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract SingleSwap {
    address public constant routerAddress =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);
// function swapExactInputSingle(uint256 amountIn) public returns (uint256 amountOut) {
//     linkToken.approve(address(swapRouter), amountIn);
//     ExactInputSingleParams memory params = ExactInputSingleParams({
//         tokenIn: address(this),
//         tokenOut: WETH,
//         fee: poolFee,
//         recipient: address(this),
//         deadline: block.timestamp,
//         amountIn: amountIn,
//         amountOutMinimum: 0,
//         sqrtPriceLimitX96: 0
//     });
//     amountOut = swapRouter.exactInputSingle(params);
// }

    function swapExactInputSingle(uint24 poolFee,uint256 amountIn,address FROG,address WETH,address Receiver)
        external
        returns (uint256 amountOut)
    {
        // IERC20(FROG).transfer(address(this), amountIn);

        IERC20(FROG).approve(address(swapRouter), (amountIn*100000));
        // IERC20(FROG).approve(address(pancake), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: FROG,
                tokenOut: WETH,
                fee: poolFee,
                recipient: Receiver,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }
}