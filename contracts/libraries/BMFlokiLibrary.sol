// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import 'bmfloki/contracts/interfaces/IBMFlokiPair.sol';
import 'bmfloki/contracts/interfaces/IBMFlokiFactory.sol';

import './SafeMath.sol';

library BMFlokiLibrary {
    using SafeMath for uint256;

    function checkAndConvertETHToWETH(address token) internal pure returns (address) {
        if (token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            return address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
        }
        return token;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        tokenA = checkAndConvertETHToWETH(tokenA);
        tokenB = checkAndConvertETHToWETH(tokenB);
        return (tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA));
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        return (
            address(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex'1f67f5b71a67d06a4b0902667899630a4bae34e1c678d87aa73f6314053f36a8' // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IBMFlokiPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getReservesByPair(
        address pair,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IBMFlokiPair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // fetches and sorts the reserves for a pair
    function getSwapFee(address factory) internal view returns (uint32 swapFee) {
        swapFee = IBMFlokiFactory(factory).swapFee();
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'BMFlokiLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'BMFlokiLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 swapFee
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'BMFlokiLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'BMFlokiLibrary: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn.mul(uint256(1000).sub(swapFee));
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountOutByPair(
        uint256 amountIn,
        address pair,
        address tokenA,
        address tokenB,
        uint32 swapFee
    ) internal view returns (uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = getReservesByPair(pair, tokenA, tokenB);
        return (getAmountOut(amountIn, reserveIn, reserveOut, swapFee));
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 swapFee
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, 'BMFlokiLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'BMFlokiLibrary: INSUFFICIENT_LIQUIDITY');
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(uint256(1000).sub(swapFee));
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'BMFlokiLibrary: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, getSwapFee(factory));
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'BMFlokiLibrary: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, getSwapFee(factory));
        }
    }
}
