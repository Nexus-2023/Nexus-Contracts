# Nexus Bridge Contract

Nexus Bridge Contract enables any rollup to stake ETH locked in their bridge. This helps rollup earn extra yield.

### How to integrate with any Bridge
- Change the [DAO address](https://github.com/Nexus-2023/Nexus-Contracts/blob/7f92f23e11926850a76f441802ca59a9613f8dc3/contracts/nexus_bridge/NexusBridge.sol#L21) that can recieve staking rewards
- To integrate with any bridge, one need to import the nexus_bridge folder into the bridge contract
- Whitelist admin address with the Nexus Contract. For this you'll have to send address to the nexus team to whitelist
- After whitelisting, you can [register your rollup](https://goerli.etherscan.io/address/0xd1c788ac548cb467b3c4b14cf1793bca3c1dcbeb#writeProxyContract#F8) using the admin address on Nexus Contract
- Set the staking limit from 0 - 10000. This will translate to 0-100%