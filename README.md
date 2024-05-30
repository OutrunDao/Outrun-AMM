**Read this in Chinese: [中文](README.cn.md)**

## OutswapV1

OutswapV1 is built based on the design principles of UniswapV2 and includes several Blast (Layer 2)-based local improvements. Specifically, OutswapV1 introduces orETH and orUSD as intermediary tokens and makes significant improvements in liquidity provider fee management. The main features are as follows:

+ **Using orETH and orUSD as Intermediary Tokens**: OutswapV1 introduces orETH and orUSD as intermediary tokens in trading pairs. This design allows Outstake to capture native yields generated by OutswapV1, increasing the protocol's revenue. 

+ **Separation of Liquidity and Market-Making Fees**: OutswapV1 improves the management of market-making fees by separating liquidity from fee collection. This allows users to collect fees without removing liquidity, providing greater flexibility and convenience for liquidity providers.

## Why built based on UniswapV2 instead of UniswapV3?

We analyzed the historical trading data of UniswapV3 and identified the following issues.

**1. Concentration of Liquidity in Mainstream Trading Pairs**
  + Mainstream and stablecoin trading pairs attract the majority of trading volume and liquidity due to their high liquidity, low volatility, and high market demand.
  + The liquidity for these pairs is often provided by professional market makers who have substantial capital and expertise in managing positions.

**2. Unfavorable for Non-Professional Market Makers**
  + With the upgrade to Uniswap V3, liquidity provision has become more complex, requiring specialized knowledge to manage positions and price ranges. For regular users, the uncertainty is too high, making it difficult to participate in market making.
  + The dominance of professional market makers in providing liquidity has led to decreased decentralization, reducing the participation of ordinary users and blurring the lines between centralized exchanges (CEX) and decentralized exchanges (DEX).

**3. Unfriendly to New Protocols and New Assets**
  + New protocols lack substantial mainstream assets, making it difficult to accumulate Total Value Locked (TVL).
  + New assets on Uniswap V3 face liquidity fragmentation issues, as it is challenging to determine upper and lower bounds for price ranges, leading to higher impermanent loss for liquidity providers (LPs).

Therefore, the initial version of Outswap-- OutswapV1, will be built based on the design principles of UniswapV2. We will only introduce the concentrated liquidity AMM version -- **OutswapV2**, after OutswapV1 has acquired sufficient liquidity.
