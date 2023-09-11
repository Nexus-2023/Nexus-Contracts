# Nexus-Contracts

This repo contains Nexus Smart Contracts that are used to enable yield generation of locked eth for Rollups 
via staking a percentage of ETH locked.

### Smart Contracts:
- **[Nexus](contracts/Nexus.sol)**: This contract is the core contract that handles all the important functionalities of Nexus Network. This also acts as a factory contract to create Rollup specific
Withdrawal Contracts which receive the validator rewards.
- **[NexusBridge](contracts/NexusBridge.sol)**: This contract contains the minimalist change needed for 
onboarding any rollup. Rollup can just import this contract and Nexus Network will be integrated.
- **[Withdrawal](contracts/Withdrawal.sol)**: This is contract that is created for rollups when they
register with Nexus Network. This contract receives rewards that are earned by validators created through
their bridge contract.

