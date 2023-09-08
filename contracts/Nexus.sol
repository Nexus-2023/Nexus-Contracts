//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Nexus {
    using EnumerableSet for EnumerableSet.AddressSet;
    struct Rollup {
        uint64 id;
        address bridgeContract;
        uint16 staking_limit;
        address withdrawal_address;
        uint64 validator_count;
        uint32 operatorCluster;
    }
    EnumerableSet.AddressSet private whitelisted_rollups;
    address public admin;
    mapping(uint64 => Rollup) public rollups;
    uint64[] public rollupIDs;
    mapping(uint32 => uint32[]) public operatorClusters;

    event RollupWhitelisted(string name, address rollup_address);
    error NotAdmin();
    error AddressAlreadyWhitelisted();
    error AddressNotWhitelisted();
    error RollupAlreadyPresent();
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }
    modifier onlyWhitelistedRollup() {
        if (!whitelisted_rollups.contains(msg.sender))
            revert AddressNotWhitelisted();
        _;
    }

    function registerRollup(
        address bridge_contract,
        uint32 operator_cluster,
        uint16 staking_limit,
        address dao_address
    ) external onlyWhitelistedRollup {}

    function changeStakingLimit(
        uint16 new_staking_limit
    ) external onlyWhitelistedRollup {}

    function whitelistRollup(
        string calldata name,
        address rollupAddress
    ) external onlyAdmin {
        if (whitelisted_rollups.contains(rollupAddress))
            revert AddressAlreadyWhitelisted();
        if (whitelisted_rollups.add(rollupAddress)) {
            emit RollupWhitelisted(name, rollupAddress);
        } else {
            revert RollupAlreadyPresent();
        }
    }
}
