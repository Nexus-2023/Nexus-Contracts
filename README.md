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
    - C token bridge: In this scenario the tokens on L2 compound in value with respect to L1 eth just like how rocketpool works
    - Rebase token bridge: In this scenario the tokens are rebased on L2 depending on the reqrds earned by validators just like LIDO
- **[NodeOperator](contracts/NodeOperator.sol)**: This contract is responsible for registering node oeprators and mantaining clusters for Nexus Network.
- **[ValidatorExecution](contracts/ValidatorExecutionRewards.sol)**: This contract recievs validator execution rewards that are sent back to the bridge contract of the rollup.

### Testing and Deploying
Testing:
- For testing the contracts one would need to enable forking in hardhat config
```
    networks: {
      hardhat: {
        forking: {
          enabled: true,
          url: process.env.HOLESKY_URL || "",
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
- Holesky network
```
npm run deploy:holesky
```
- For verifying the contracts:
```
npm run verify:holesky
```

All the contracts address after deployment are stored in **output_network.json**