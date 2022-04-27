//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2ERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract UniswapV2Pair is IUniswapV2Pair, IUniswapV2ERC20 {
    // TODO: have to write 30 lines of code of uniswap

    // TODO
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimeStampLast;

    uint256 public price0ComulativeLast;
    uint256 public price1ComulativeLast;
    // reseve0 * reserve1, as of immediately after the most recent liquidity event
    uint256 public kLast;

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimeStampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimeStampLast = blockTimeStampLast;
    }

    // TODO: https://ethereum.stackexchange.com/questions/88069/what-does-the-function-abi-encodewithselectorbytes4-selector-returns-by

    // TODO: Unclear with asnswer encodeWithSelector

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );

        require(success && (data.length == 0 || abi.decode(data,(bool))),'UniswapV2: TRANSFER_FAILED');
    }
}
