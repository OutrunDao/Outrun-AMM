//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IOutrunAMMFactory {
    function pointsOperator() external view returns (address);

    function swapFeeRate() external view returns (uint256);

    function feeTo() external view returns (address);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);


    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;


    error ZeroAddress();

    error PairExists();

    error IdenticalAddresses();
    

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
}
