**Read this in Chinese: [中文](README.cn.md)**

## Outrun AMM

Outrun AMM is built on traditional AMM and includes several innovative improvements. The main features are as follows:

+ **Using orETH and orUSD as Intermediary Tokens**: Outrun AMM introduces orETH and orUSD as intermediary tokens in trading pairs. This design allows Outstake to capture native yields generated by Outrun AMM, increasing the protocol's revenue.

+ **Separation of Liquidity and Market-Making Fees**: Outrun AMM improves the management of market-making fees by separating liquidity from fee collection. This allows users to collect fees without removing liquidity, providing greater flexibility and convenience for liquidity providers.

+ **New Fee Tiers**: All Uniswap v2 pools have a fixed swap fee of 0.3%, which results in a lack of flexibility for LPs (liquidity providers) who cannot seek different fee structures based on the assets they provide to the exchange. Outrun AMM will introduce new fee tiers for pool creators, allowing them to build different trading pools for various types of assets when launching pools on Outrun AMM.

+ **Referral Commission Engine**: Outrun AMM is currently the only automated market maker on the market integrated with a referral commission engine. We have redesigned the underlying code and opened the referral bonus engine to everyone, thereby increasing the composability of the protocol. The rewards for the referral bonus come from the protocol fees and do not harm the interests of LPs. At the same time, this attracts more transactions, bringing higher income to LPs.

### Why build on traditional AMM instead of concentrated liquidity AMM?

We analyzed the historical trading data of most concentrated liquidity AMMs on the market and found the following issues.

**Liquidity Concentration in Major Trading Pairs**

+ Major and stablecoin trading pairs attract the majority of trading volume and liquidity due to their high liquidity, low volatility, and high market demand.
+ The liquidity for these pairs is often provided by professional market makers who have significant capital and professional position management capabilities.

**Not favorable for non-professional market makers**

+ In concentrated liquidity AMMs, providing liquidity becomes more complex and requires professional knowledge to manage positions and price ranges. This high level of uncertainty makes it difficult for ordinary users to participate.
+ The liquidity provision curve in concentrated liquidity AMMs is not smooth and often faces the issue of unbalanced liquidity, leading to higher impermanent loss for liquidity providers (LPs), where losses can outweigh gains.
+ The dominance of professional market makers in providing liquidity reduces the level of decentralization, making it increasingly difficult for ordinary users to participate, thus blurring the lines between CEX and DEX.

**Unfriendly to New DEX Protocols and New Assets**

+ Concentrated liquidity AMMs have high market-making thresholds, and new protocols lack a large number of mainstream assets, making it difficult to accumulate Total Value Locked (TVL) for the protocol.
+ New assets face the problem of liquidity fragmentation on centralized liquidity AMMs. New assets often experience significant volatility, making it difficult to determine upper and lower price boundaries. This volatility can lead to sudden liquidity collapses, negatively impacting the project.

Therefore, the initial version of Outswap—Outrun AMM, is built based on the design philosophy of Uniswap v2. Only after Outrun AMM has gained sufficient liquidity will we launch the concentrated liquidity AMM version—**Outrun CLAMM**.

## Referral Commission Engine

### The Importance of Referral Commission

The importance of referral commission for cryptocurrency exchanges cannot be overstated, playing a crucial role in user acquisition, community building, and market promotion:

**User Growth**

+ **Attracting New Users**: Referral commission incentivize existing users to invite new users to register and trade, effectively expanding the exchange's user base and transaction volume.

+ **Reducing Customer Acquisition Costs**: Compared to traditional advertising and marketing methods, referral commissions are cost-effective and efficient.

+ **Building Trust**: New users tend to trust recommendations from friends or acquaintances, thereby increasing their trust and loyalty.

**Increasing User Engagement**

+ **Encouraging Participation**: Referral commissions motivate existing users to actively promote and invite friends, increasing the exchange's user activity and community interaction.

+ **Enhancing User Stickiness**: Commission programs encourage users to stay engaged and participate in exchange activities, enhancing their stickiness and loyalty.

**Market Promotion and Brand Awareness**

+ **Wide Dissemination**: Users actively promote the exchange through referral commissions, achieving widespread market dissemination and brand exposure.

+ **Viral Marketing Effect**: Through user referrals, rapid expansion of brand awareness is achieved, creating a viral marketing effect.

+ **Enhancing Brand Image**: User referrals can enhance the exchange's brand image and market recognition.

**Enhancing Competitiveness**

+ **Differentiation Strategy**: Referral commission programs serve as a differentiation strategy, helping exchanges stand out in competitive markets.

+ **Improving User Retention**: Users motivated by referral commissions have more incentives to stay on the exchange and invite others, thereby enhancing user retention rates.

Many well-known exchanges like Binance, Coinbase, and KuCoin have experienced rapid growth through referral commission programs. For instance, Binance's referral commission program not only attracted a large number of new users but also significantly increased platform trading volume and activity, becoming a critical factor in its rapid rise.

### Referral commission design for Outrun AMM

Designing a referral commission program for a decentralized exchange (DEX) requires considering its significant differences from centralized exchanges (CEX). The referral commission program for Outrun AMM focuses on the following points to fully leverage its decentralized nature and the advantages of smart contracts, while ensuring user experience and composability:

**Use of Smart Contracts**

+ **Automated Distribution**: Execute referral commission through smart contracts to automatically calculate and distribute commission upon trade completion. This ensures transaction transparency and prevents any manual tampering.

+ **Instant Settlement**: Smart contracts can instantly distribute referral commissions to referrers after each trade. This not only increases user trust but also boosts user engagement.

**User Experience**

+ **Simple Referral Process**: Ensure that users can easily generate and share referral links. The referred users complete registration by trading through the link.

+ **Clear Rewards Display**: Provide a user-friendly interface that clearly shows the accumulated and settled referral rewards. Users should be able to easily view their referral earnings.

**Composability**

+ **Openness**: Allow anyone to build new referral services based on Outrun AMM without relying on a single peripheral contract. This way, third-party services can direct trades and earn referral fees.

+ **Protocol Composability**: Enhance protocol composability by making referral commission features open, enabling third parties to develop new DeFi products based on the referral engine, thereby enriching the entire ecosystem.

**Enhancing Market Makers' Interests**

+ **Source of Referral Fees**: Referral fees comes from a portion(20%) of the protocol fee, not from the market makers' due fees. This ensures that the referral commission mechanism does not harm the interests of market makers.

+ **Increasing Market Makers' Earnings**: The referral engine helps increase trading activity, attracting more trading volume, and thereby increasing the earnings of market makers.
