//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import { Test, console2 } from "forge-std/Test.sol";
import { OutswapV1Router } from "src/router/OutswapV1Router.sol";
// import { OutswapV1Pair } from "src/core/OutswapV1Pair.sol";

import {TestERC20} from "./utils/TestERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRETH} from './interfaces/IRETH.sol';
import { IOutswapV1Factory} from "src/core/interfaces/IOutswapV1Factory.sol";

string constant RETHAtricle = "test/utils/RETH.json";
string constant RUSDAtricle = "test/utils/RUSD.json";
string constant factoryAtricle = "out/OutswapV1Factory.sol/OutswapV1Factory.json";
string constant routerAtricle = "out/OutswapV1Router.sol/OutswapV1Router.json";

contract OutVault {
	address public owner;
	constructor(){
		owner = msg.sender;
	}

	function withdraw(address sender, uint256 amount) external {
	    payable(sender).transfer(amount);
	}
	receive() external payable {}
	fallback() external payable {}
    
}

contract BaseDeploy is Test {

	address public deployer = vm.envAddress("LOCAL_DEPLOYER");
	address public user = makeAddr("user");

	IOutswapV1Factory internal poolFactory;
	OutswapV1Router internal swapRouter;

	address internal RETH9;
	address internal RUSD9;
	address internal USDB;

	address internal ethVault;
	address internal usdVault;

	uint256 immutable tokenNumber = 3;

	address[] tokens;

	/* 
    初始化：建立好一个测试环境，包括部署池子工厂合约，创建测试代币，创建测试账户等。
     */
	function setUp() public virtual {
		// bytes32 INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(OutswapV1Pair).creationCode));
		// console2.logBytes32(INIT_CODE_PAIR_HASH);
		vm.startPrank(deployer);

		ethVault = address(new OutVault());
		usdVault = address(new OutVault());

		RETH9 = deployCode(RETHAtricle, abi.encode(deployer));
		RUSD9 = deployCode(RUSDAtricle, abi.encode(deployer));
		USDB = address(new TestERC20(type(uint256).max / 2));

		IRETH(payable(RETH9)).setOutETHVault(ethVault);

		vm.deal(deployer, 10e10 ether);
		IRETH(payable(RETH9)).deposit{value: 100 ether}();

		// poolFactory = new OutswapV1Factory(deployer);
		address factory = deployCode(factoryAtricle, abi.encode(deployer));
		poolFactory = IOutswapV1Factory(factory);

		swapRouter = new OutswapV1Router(address(poolFactory), RETH9, RUSD9, USDB);
		
		getToken();

		vm.stopPrank();
	}

	function newRouter() public returns (address) {
	    address factory = deployCode(factoryAtricle, abi.encode(deployer));
		poolFactory = IOutswapV1Factory(factory);

		return address(new OutswapV1Router(address(poolFactory), RETH9, RUSD9, USDB));
	}

	function getToken() internal {
		for (uint256 i = 0; i < tokenNumber; i++) {
			address token = address(new TestERC20(type(uint256).max / 2));
			tokens.push(token);
			safeApprove(
				token,
				address(swapRouter),
				type(uint256).max / 2
			);
		}
	}

	function addLiquidity(
        address tokenA,
        address tokenB,
		uint amount0,
		uint amount1
	)
		internal
		virtual
		returns (uint , uint , uint )
	{
		console2.log("addLiquidity");
		(tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

		return swapRouter.addLiquidity(
        tokenA,
        tokenB,
        amount0,
        amount1,
        0,
        0,
        deployer,
        block.timestamp + 1 days);
	}

	function addLiquidityETH(
        address tokenA,
		uint amount0
	)
		public
		virtual
		returns (uint , uint , uint )
	{
		// (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		console2.log("addLiquidityETH");

		return swapRouter.addLiquidityETH(
        tokenA,
        amount0,
        0,
        0,
        deployer,
        block.timestamp + 1 days);
	}

	function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

	function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }
}
