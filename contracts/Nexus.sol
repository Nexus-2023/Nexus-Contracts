//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Withdraw} from "./Withdrawal.sol";
import {INexusBridge} from "./interfaces/INexusBridge.sol";

/**
 * @title Nexus Core Contract
 * @dev This contract is heart and soul of Nexus Network and is used for Operations like
 * 1. Onboarding of rollup to Nexus Network
 * 2. Change in staking limit for rollup
 * 3. Whitelisting rollup address
 * 4. Submitting keys to rollup bridge
 * 5. Submitting keyshares to SSV contract
 * 6. Recharge funds in SSV contract for validator operation
 * 7. Reward distribution for rollup to DAO and Nexus Fee Contract
 */
contract Nexus {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Rollup {
        address bridgeContract;
        uint16 stakingLimit;
        address withdrawalAddress;
        uint64 validatorCount;
        uint32 operatorCluster;
    }
    EnumerableSet.AddressSet private whitelistedRollups;
    address public constant ADMIN = 0x4142676ec5706706D3a0792997c4ea343405376b;
    address public offChainBot;
    mapping(address => Rollup) public rollups;
    mapping(uint32 => uint32[]) public operatorClusters;

    event RollupWhitelisted(string name, address rollup_address);
    error NotAdmin();
    error NotNexusBot();
    error AddressAlreadyWhitelisted();
    error AddressNotWhitelisted();
    error RollupAlreadyPresent();
    error RollupAlreadyRegistered();

    event RollupRegistered(address adminAddress);
    event StakingLimitChanged(uint16 oldStakingLimit, uint16 newStakingLimit);
    modifier onlyAdmin() {
        if (msg.sender != ADMIN) revert NotAdmin();
        _;
    }

    modifier onlyOffChainBot() {
        if (msg.sender != offChainBot) revert NotNexusBot();
        _;
    }

    modifier onlyWhitelistedRollup() {
        if (!whitelistedRollups.contains(msg.sender))
            revert AddressNotWhitelisted();
        _;
    }

    function registerRollup(
        address bridge_contract,
        uint32 operator_cluster,
        uint16 staking_limit,
        address dao_address
    ) external onlyWhitelistedRollup {
        if (rollups[msg.sender].bridgeContract != address(0))
            revert RollupAlreadyRegistered();
        Withdraw withdrawal_contract = new Withdraw(dao_address, 1000);
        rollups[msg.sender] = Rollup(
            bridge_contract,
            staking_limit,
            address(withdrawal_contract),
            0,
            operator_cluster
        );
        emit RollupRegistered(msg.sender);
        (bool success, bytes memory data) = bridge_contract.call(
            abi.encodeWithSelector(
                INexusBridge.setWithdrawal.selector,
                address(withdrawal_contract)
            )
        );
    }

    function changeStakingLimit(
        uint16 new_staking_limit
    ) external onlyWhitelistedRollup {
        emit StakingLimitChanged(
            rollups[msg.sender].stakingLimit,
            new_staking_limit
        );
        rollups[msg.sender].stakingLimit = new_staking_limit;
    }

    function depositValidatorRollup() external onlyOffChainBot {}

    function depositValidatorShares() external onlyOffChainBot {}

    function whitelistRollup(
        string calldata name,
        address rollupAddress
    ) external onlyAdmin {
        if (whitelistedRollups.contains(rollupAddress))
            revert AddressAlreadyWhitelisted();
        if (whitelistedRollups.add(rollupAddress)) {
            emit RollupWhitelisted(name, rollupAddress);
        } else {
            revert RollupAlreadyPresent();
        }
    }
}
