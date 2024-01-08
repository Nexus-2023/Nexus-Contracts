# Nexus-Contracts

This repo contains Nexus Smart Contracts that are used to enable yield generation of locked eth for Rollups
via staking a percentage of ETH locked.

### Smart Contracts:
- **[Nexus](contracts/Nexus.sol)**: This contract is the core contract that handles all the important functionalities of Nexus Network like:
    - Rollup registration
    - Managing staking limit
    - Depositing validator keys to rollup bridges for activation
    - Depositing validator shares so that SSV node operators can start validating
    - Validator key exit management
- **[NodeOperator](contracts/NodeOperator.sol)**: This contract is responsible for NodeOperator Onboarding and in future will be used for monitoring as well.
- **[NexusBridge](contracts/nexus_bridge/NexusBaseBridge.sol)**: This contract contains the minimalist change needed for
onboarding any rollup. Rollup has 3 choices as of now for bridge design:
    - DAO bridge: In this scenario, all the validator rewards are given back to the DAO
- **[Withdrawal](contracts/Withdrawal.sol)**: This is contract that is created for rollups when they
register with Nexus Network. This contract receives rewards that are earned by validators created through
their bridge contract.

### Testing and Deploying
Testing:
- For testing the contracts one would need to enable forking in hardhat config
```
    networks: {
      hardhat: {
        forking: {
          enabled: true,
          url: process.env.GOERLI_URL || "",
        },
      }
    }
```
- You can run the following command to run the unit test cases
```
npm run test:all
```

Deploying:
- Local network
```
npm run deploy:local
```
- Goerli network
```
npm run deploy:goerli
```
- For verifying the contracts:
```
npm run verify:goerli
```

All the contracts address after deployment are stored in **output_network.json**