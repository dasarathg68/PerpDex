# PerpDex: Decentralized Perpetual Exchange on Uniswap v4

PerpDex is a decentralized perpetual trading protocol built on Uniswap v4, enabling leveraged trading using LP liquidity. The protocol uses EigenLayer AVSs for off-chain services like liquidation tracking, MEV resistance, and price discovery.

## Architecture

The protocol consists of three main components:

1. **PerpetualHook**: A Uniswap v4 hook that manages the interaction with Uniswap pools, tracking liquidity and open interest.
2. **PerpPositionManager**: Manages leveraged trading positions, including opening, closing, and liquidation.
3. **PerpOracle**: Provides price feeds for trading pairs, with built-in staleness checks and update frequency limits.

## System Flow

### Trading Flow

1. **Opening a Position**

   - Trader submits position request to `PerpPositionManager`
   - Position Manager:
     - Validates position parameters
     - Checks available liquidity via `PerpetualHook`
     - Verifies leverage limits (2x-10x based on utilization)
     - Opens position using Uniswap V4 pool liquidity

2. **Position Monitoring**

   - `PerpOracle` receives price updates from EigenLayer AVS
   - Position Manager tracks:
     - Position value
     - Maintenance margin requirements
     - Liquidation thresholds

3. **Liquidity Management**

   - `PerpetualHook` monitors pool state:
     - Tracks liquidity additions/removals
     - Updates open interest on trades
     - Calculates real-time utilization
     - Adjusts leverage limits dynamically

4. **Liquidation Process**
   - Continuous position monitoring
   - Automatic liquidation triggers:
     - Position value falls below maintenance margin
     - Adverse price movement beyond threshold
   - MEV-resistant execution through EigenLayer AVS

### Risk Management

1. **Dynamic Leverage Limits**

   ```
   Utilization  |  Max Leverage
   0%          |  10x
   50%         |  6x
   100%        |  2x
   ```

2. **Pool Utilization**

   ```
   Utilization = (Total Open Interest / Total Pool Liquidity) * 100%
   ```

3. **Position Safety**
   - Maintenance margin: 5% of position size
   - Real-time price monitoring
   - Automated liquidation system

## Usage

### Opening a Position

To open a leveraged position:

1. Approve the Position Manager to spend your tokens
2. Call `openPosition` with:
   - Token address
   - Position direction (long/short)
   - Margin amount
   - Leverage (up to 10x)

Example:

```solidity
// Open a 5x long position with 1 ETH margin
positionManager.openPosition(
    tokenAddress,
    true, // long
    1 ether,
    5
);
```

### Closing a Position

To close a position:

```solidity
positionManager.closePosition(positionId);
```

### Liquidation

Positions are automatically monitored for liquidation. A position becomes liquidatable when:

- Current margin < Maintenance margin (5% of position size)
- Price moves against the position beyond the liquidation threshold

## Security

The protocol implements several security measures:

1. Price feed staleness checks
2. Minimum update intervals for oracle prices
3. Dynamic leverage limits based on pool utilization
4. Maintenance margin requirements
5. MEV protection through EigenLayer AVS
