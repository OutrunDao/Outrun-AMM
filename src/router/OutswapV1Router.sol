//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/TransferHelper.sol";
import "../core/interfaces/IOutswapV1Factory.sol";
import "./interfaces/IOutswapV1Router.sol";
import "../core/interfaces/IOutswapV1ERC20.sol";
import "./interfaces/IRETH.sol";
import "./interfaces/IRUSD.sol";
import "../libraries/OutswapV1Library.sol";

contract OutswapV1Router is IOutswapV1Router {
    address public immutable override factory;
    address public immutable RETH;
    address public immutable RUSD;
    address public immutable USDB;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "OutswapV1Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _reth, address _rusd, address _usdb) {
        factory = _factory;
        RETH = _reth;
        RUSD = _rusd;
        USDB = _usdb;
        IERC20(_usdb).approve(_rusd, type(uint256).max);
    }

    receive() external payable {}

    /**
     * ADD LIQUIDITY *
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IOutswapV1Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IOutswapV1Factory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = OutswapV1Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = OutswapV1Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "OutswapV1Router: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = OutswapV1Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "OutswapV1Router: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = OutswapV1Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IOutswapV1Pair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        (amountToken, amountETH) =
            _addLiquidity(token, RETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        address pair = OutswapV1Library.pairFor(factory, token, RETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IRETH(RETH).deposit{value: amountETH}();
        assert(IRETH(RETH).transfer(pair, amountETH));
        liquidity = IOutswapV1Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function addLiquidityUSDB(
        address token,
        uint256 amountTokenDesired,
        uint256 amountUSDBDesired,
        uint256 amountTokenMin,
        uint256 amountUSDBMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountUSDB, uint256 liquidity)
    {
        (amountToken, amountUSDB) =
            _addLiquidity(token, RUSD, amountTokenDesired, amountUSDBDesired, amountTokenMin, amountUSDBMin);

        address pair = OutswapV1Library.pairFor(factory, token, RUSD);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        TransferHelper.safeTransferFrom(USDB, msg.sender, address(this), amountUSDB);
        IRUSD(RUSD).deposit(amountUSDB);
        assert(IRUSD(RUSD).transfer(pair, amountUSDB));
        liquidity = IOutswapV1Pair(pair).mint(to);
    }

    function addLiquidityETHAndUSDB(
        uint256 amountUSDBDesired,
        uint256 amountETHMin,
        uint256 amountUSDBMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountETH, uint256 amountUSDB, uint256 liquidity)
    {
        (amountETH, amountUSDB) = _addLiquidity(RETH, RUSD, msg.value, amountUSDBDesired, amountETHMin, amountUSDBMin);

        address pair = OutswapV1Library.pairFor(factory, RETH, RUSD);
        IRETH(RETH).deposit{value: amountETH}();
        assert(IRETH(RETH).transfer(pair, amountETH));
        TransferHelper.safeTransferFrom(USDB, msg.sender, address(this), amountUSDB);
        IRUSD(RUSD).deposit(amountUSDB);
        assert(IRUSD(RUSD).transfer(pair, amountUSDB));
        liquidity = IOutswapV1Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = OutswapV1Library.pairFor(factory, tokenA, tokenB);
        IOutswapV1Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IOutswapV1Pair(pair).burn(to);
        (address token0,) = OutswapV1Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "OutswapV1Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "OutswapV1Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) =
            removeLiquidity(token, RETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, amountToken);
        IRETH(RETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityUSDB(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountUSDBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountUSDB) {
        (amountToken, amountUSDB) =
            removeLiquidity(token, RUSD, liquidity, amountTokenMin, amountUSDBMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, amountToken);
        IRUSD(RUSD).withdraw(amountUSDB);
        TransferHelper.safeTransfer(USDB, to, amountUSDB);
    }

    function removeLiquidityETHAndUSDB(
        uint256 liquidity,
        uint256 amountETHMin,
        uint256 amountUSDBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountETH, uint256 amountUSDB) {
        (amountETH, amountUSDB) =
            removeLiquidity(RETH, RUSD, liquidity, amountETHMin, amountUSDBMin, address(this), deadline);
        IRETH(RETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
        IRUSD(RUSD).withdraw(amountUSDB);
        TransferHelper.safeTransfer(USDB, to, amountUSDB);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = OutswapV1Library.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IOutswapV1ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
        address pair = OutswapV1Library.pairFor(factory, token, RETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IOutswapV1ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    function removeLiquidityUSDBWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountUSDBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountToken, uint256 amountUSDB) {
        address pair = OutswapV1Library.pairFor(factory, token, RUSD);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IOutswapV1ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountUSDB) = removeLiquidityUSDB(token, liquidity, amountTokenMin, amountUSDBMin, to, deadline);
    }

    function removeLiquidityETHAndUSDBWithPermit(
        uint256 liquidity,
        uint256 amountETHMin,
        uint256 amountUSDBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountETH, uint256 amountUSDB) {
        address pair = OutswapV1Library.pairFor(factory, RETH, RUSD);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IOutswapV1ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountETH, amountUSDB) = removeLiquidityETHAndUSDB(liquidity, amountETHMin, amountUSDBMin, to, deadline);
    }

    /**
     * REMOVE LIQUIDITY (supporting fee-on-transfer tokens) *
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(token, RETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IRETH(RETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountETH) {
        address pair = OutswapV1Library.pairFor(factory, token, RETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IOutswapV1ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    function removeLiquidityUSDBSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountUSDBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountUSDB) {
        (, amountUSDB) = removeLiquidity(token, RUSD, liquidity, amountTokenMin, amountUSDBMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IRUSD(RUSD).withdraw(amountUSDB);
        TransferHelper.safeTransfer(USDB, to, amountUSDB);
    }

    function removeLiquidityUSDBWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountUSDBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountUSDB) {
        address pair = OutswapV1Library.pairFor(factory, token, RUSD);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IOutswapV1ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountUSDB = removeLiquidityUSDBSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountUSDBMin, to, deadline
        );
    }

    /**
     * SWAP *
     */
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = OutswapV1Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? OutswapV1Library.pairFor(factory, output, path[i + 2]) : _to;
            IOutswapV1Pair(OutswapV1Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = OutswapV1Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = OutswapV1Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "OutswapV1Router: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == RETH, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IRETH(RETH).deposit{value: amounts[0]}();
        assert(IRETH(RETH).transfer(OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == RETH, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "OutswapV1Router: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IRETH(RETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == RETH, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IRETH(RETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == RETH, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, "OutswapV1Router: EXCESSIVE_INPUT_AMOUNT");
        IRETH(RETH).deposit{value: amounts[0]}();
        assert(IRETH(RETH).transfer(OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    function swapExactUSDBForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == RUSD, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(USDB, msg.sender, address(this), amounts[0]);
        IRUSD(RUSD).deposit(amounts[0]);
        assert(IRUSD(RUSD).transfer(OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactUSDB(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == RUSD, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "OutswapV1Router: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IRUSD(RUSD).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransfer(USDB, to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForUSDB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == RUSD, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IRUSD(RUSD).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransfer(USDB, to, amounts[amounts.length - 1]);
    }

    function swapUSDBForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == RUSD, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "OutswapV1Router: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(USDB, msg.sender, address(this), amounts[0]);
        IRUSD(RUSD).deposit(amounts[0]);
        assert(IRUSD(RUSD).transfer(OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    /**
     * SWAP with Pair(ETH, USDB) *
     */
    function swapExactETHForUSDB(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == RETH && path[path.length - 1] == RUSD, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IRETH(RETH).deposit{value: amounts[0]}();
        assert(IRETH(RETH).transfer(OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, address(this));
        IRUSD(RUSD).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransfer(USDB, to, amounts[amounts.length - 1]);
    }

    function swapUSDBForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == RUSD && path[path.length - 1] == RETH, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "OutswapV1Router: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(USDB, msg.sender, address(this), amounts[0]);
        IRUSD(RUSD).deposit(amounts[0]);
        TransferHelper.safeTransfer(path[0], OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IRETH(RETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactUSDBForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == RUSD && path[path.length - 1] == RETH, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(USDB, msg.sender, address(this), amounts[0]);
        IRUSD(RUSD).deposit(amounts[0]);
        TransferHelper.safeTransfer(path[0], OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IRETH(RETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactUSDB(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == RETH && path[path.length - 1] == RUSD, "OutswapV1Router: INVALID_PATH");
        amounts = OutswapV1Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, "OutswapV1Router: EXCESSIVE_INPUT_AMOUNT");
        IRETH(RETH).deposit{value: amounts[0]}();
        assert(IRETH(RETH).transfer(OutswapV1Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, address(this));
        IRUSD(RUSD).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransfer(USDB, to, amounts[amounts.length - 1]);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    /**
     * SWAP (supporting fee-on-transfer tokens) *
     */
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = OutswapV1Library.sortTokens(input, output);
            IOutswapV1Pair pair = IOutswapV1Pair(OutswapV1Library.pairFor(factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = OutswapV1Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? OutswapV1Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutswapV1Library.pairFor(factory, path[0], path[1]), amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        require(path[0] == RETH, "OutswapV1Router: INVALID_PATH");
        uint256 amountIn = msg.value;
        IRETH(RETH).deposit{value: amountIn}();
        assert(IRETH(RETH).transfer(OutswapV1Library.pairFor(factory, path[0], path[1]), amountIn));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == RETH, "OutswapV1Router: INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutswapV1Library.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = IERC20(RETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IRETH(RETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function swapExactUSDBForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path[0] == RUSD, "OutswapV1Router: INVALID_PATH");
        IRUSD(RUSD).deposit(amountIn);
        assert(IRUSD(RUSD).transfer(OutswapV1Library.pairFor(factory, path[0], path[1]), amountIn));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForUSDBSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == RUSD, "OutswapV1Router: INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutswapV1Library.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = IERC20(RUSD).balanceOf(address(this));
        require(amountOut >= amountOutMin, "OutswapV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IRUSD(RUSD).withdraw(amountOut);
        TransferHelper.safeTransfer(USDB, to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB)
        public
        pure
        virtual
        override
        returns (uint256 amountB)
    {
        return OutswapV1Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        virtual
        override
        returns (uint256 amountOut)
    {
        return OutswapV1Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        virtual
        override
        returns (uint256 amountIn)
    {
        return OutswapV1Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return OutswapV1Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return OutswapV1Library.getAmountsIn(factory, amountOut, path);
    }
}
