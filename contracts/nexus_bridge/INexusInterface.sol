//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INexusInterface {

    struct Cluster {
        /// @dev The number of validators in the cluster
        uint32 validatorCount;
        /// @dev The index of network fees related to this cluster
        uint64 networkFeeIndex;
        /// @dev The last index calculated for the cluster
        uint64 index;
        /// @dev Flag indicating whether the cluster is active
        bool active;
        /// @dev The balance of the cluster
        uint256 balance;
    }

    struct Rollup {
        address bridgeContract;
        uint16 stakingLimit;
        uint64 validatorCount;
        uint64 operatorCluster;
    }
    struct Validator {
        bytes pubKey;
        bytes withdrawalAddress;
        bytes signature;
        bytes32 depositRoot;
    }
    struct ValidatorShares {
        bytes pubKey;
        uint64[] operatorIds;
        bytes sharesEncrypted;
        uint256 amount;
        Cluster cluster;
    }
    struct RollupRewardUpdate{
        address rollupAdmin;
        uint256 amount;
        bool slashing;
    }

    error NotNexusBot();
    error AddressAlreadyWhitelisted();
    error AddressNotWhitelisted();
    error RollupAlreadyPresent();
    error RollupAlreadyRegistered();
    error KeyNotDeposited();
    error NexusAddressNotFound();
    error InvalidKeySupplied();
    error ClusterAlreadyExited();

    event RollupWhitelisted(string name, address rollupAddress);
    event RollupRegistered(address rollupAdmin, address withdrawalAddress,uint16 stakingLimit,uint64 operatorCluster);
    event StakingLimitChanged(
        address rollupAdmin,
        uint16 oldStakingLimit,
        uint16 newStakingLimit
    );
    event ValidatorSubmitted(bytes pubKey, address rolupAdmin);
    event ValidatorShareSubmitted(bytes pubKey, address rolupAdmin,uint256 amount);
    event ClusterAdded(uint64 clusterId, uint64[] operatorIds);
    event SSVRecharged(address sender, uint256 amount);
    event ClusterRecharged(uint64 clusterId,uint256 amount);
    event RollupRewardsUpdated(address admin,uint256 amount,bool slashing);
    event ValidatorExited(address admin,bytes pubKey);

    function depositValidatorRollup(
        address _rollupAdmin,
        Validator[] calldata _validators
    ) external;

    function depositValidatorShares(
        address _rollupAdmin,
        ValidatorShares calldata _validatorShare
    ) external;

}
