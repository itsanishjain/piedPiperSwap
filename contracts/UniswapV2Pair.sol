//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2ERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Callee.sol";

import "../interfaces/IUniswapV2Factory.sol";

import "./libraries/Math.sol";

// NOTE: Source: https://betterprogramming.pub/uniswap-smart-contract-breakdown-ea20edf1a0ff

contract UniswapV2Pair is IUniswapV2Pair, IUniswapV2ERC20 {
    // TODO: have to write 30 lines of code of uniswap

    /*

    when you want to call a smart contract without knowing its ABI

    
        well i guess you know a single function but not necessarily want to create an interface for it
        perhaps because you are calling arbitrary functions
    for e.g. multisig wallets can do anything possible in blockchain, but multisig wallets themselves are smart contracts
    so they need to be able to call arbitrary functions on other contracts
    and there is no way to have the ABI of literally every single possible thing on ethereum
    so you use the low level call functions and encode with function selectors to call those functio

    */

    // TODO
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    // SELECTOR allows you to call the ERC-20 contract via its ABI

    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory; // address who deploys
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

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "UniswapV2: TRANSFER_FAILED"
        );
    }

    // TODO: Skiping the events

    // event Mint(address indexed sender, uint amount0, uint amount1);

    // event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    // emit Mint(0x1234,12);

    constructor() {
        factory = msg.sender;
    }

    // called once by the owner to set factory at the time of deployment

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UNISWAP: FORBIDDEN");

        token0 = _token0;
        token1 = _token1;
    }

    /*
        The _update function below is called whenever there are new funds deposited or withdrawn by the liquidity providers or tokens are swapped by the traders.
                         OR
        update reserves and, on the first call per block, price accumulators


        Some interesting maths

        uint256 MAX_INT = 
        115792089237316195423570985008687907853269984665640564039457584007913129639935

                        OR

        uint256 MAX_INT = uint256(-1)

        link to learn more about this

        https://forum.openzeppelin.com/t/using-the-maximum-integer-in-solidity/3000




    */

    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        /* 
    NOTE: using 0.8.4 and above while orignal code uses "pragma solidity =0.5.16" and Now Overflow and uderflows sloves so just comment this piece of code.

    */

        // require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');

        // TODO: Why mod 2**32 is used, Just to typecast

        uint32 blockTimeStamp = uint32(block.timestamp % 2**32);

        uint32 timeElapsed = blockTimeStamp - blockTimeStampLast;

        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            /* 
        Note: Don't know what these code are doing

            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;

            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;   
        */

            // Here is my version of above code
            price0ComulativeLast += (_reserve1 / _reserve0) * timeElapsed;

            price1ComulativeLast += (_reserve0 / _reserve1) * timeElapsed;
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimeStampLast = blockTimeStamp;

        emit Sync(reserve0, reserve1);
    }

    // Here we complete 85 lines of code

    /*
      Protocol fee — Uniswap v2 introduced a switchable protocol fee. This protocol fee goes to the Uniswap team for their efforts in maintaining Uniswap. At the moment, this protocol fee is turned off but it can be turned on in the future. When it’s on, the traders will still pay the same fee for trading but 1/6 of this fee will now go to the Uniswap team and the rest 5/6 will go to the liquidity providers as the reward for providing their funds. 

      0.3% of 1280000000
    */

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)

    function _mintFee(uint112 _reserve0, uint112 _reserve1)
        private
        returns (bool feeOn)
    {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);

        uint256 _kLast = kLast; // gas saving

        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0) * _reserve1);
                uint256 rootKLast = Math.sqrt(_kLast);

                if (rootK > rootKLast) {
                    // TODO: Don't know why this error comes YET

                    uint256 numerator = totalSupply * (rootK - rootKLast);
                    uint256 denominator = rootK * 5 + rootKLast;

                    uint256 liquidity = numerator / denominator;

                    if (liquidity > 0) {
                        // TODO: Need to create this function
                        _mint(feeTo, liquidity);
                    }
                }
            } else if (_kLast != 0) {
                kLast = 0;
            }
        }
    }

    // DONE Coding 108 lines

    /*
    
        Minting is when a liquidity provider adds funds to the pool and as a result, new pool ownership tokens are minted "Uniswap tokens"


        Burning is the opposite — liquidity provider withdraws funds (and the accumulated rewards) and his pool ownership tokens are burned (destroyed).
    
    */

    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); /// gas savings

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);

        // TODO: Have to work on UniswapV2ERC20.sol
        uint256 _totalsupply = totalSupply; // gas saving, Must be defined here since totalSupply can update in _mintFee

        if (_totalsupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;

            /* 
                If totalSupply is 0 it means pool is brand new so we need to lock in 
                Minimu_liquidity amount pool ownership tokens to avoid division by 0 

                "liquidity" variable => is the amount of new "pool ownership tokens" that need to be minted to the liquidity provider. The liquidity provider gets a proportional amount of pool ownership tokens depending on how much new funds he provides
            */
            _mint(address(0), MINIMUM_LIQUIDITY);
        }
        liquidity = Math.min(
            (amount0 * _totalSupply) / _reserve0,
            (amount1 * totalSupply) / _reserve1
        );

        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) {
            // reserve0 and reserve1 are up-to-date
            kLast = uint256(reserve0 * reserve1);

            emit Burn(msg.sender, amount0, amount1, to);
        }
    }

    // DONE 155 Lines of code

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(
            amount0Out > 0 || amount1Out,
            "Uniswap: INSUFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "Uniswap: INSUFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;

        {
            // scope for _token{0,1}, avoids stack too deep errors

            address _token0 = token0;
            address _token1 = token1;

            require(to != _token0 && to != _token1, "Uniswap: INVALID_TO");

            if (amount0Out > 0) {
                _safeTransfer(_token0, to, amount0Out);
            }
            if (amount1Out > 0) {
                _safeTransfer(_token1, to, amount1Out);
            }
            if (data.length > 0) {
                IUniswapV2Callee(to).uniswapV2Call(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            }

            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;

        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;

        require(
            amount0In > 0 || amount1In > 0,
            "UniswapV2: INSUFFICIENT_INPUT_AMOUNT"
        );

        {
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;

            uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;

            require(
                balance0Adjusted * balance1Adjusted >=
                    uint256(_reserve1) * uint256(_reserve1) * 1000**2,
                "UniswapV2: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // DONE 185 lines of code 

    /*
        still things like adjusted balance is not clear
     */
}


