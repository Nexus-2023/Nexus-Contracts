//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ISSVNetworkCore} from "./ISSVNetwork.sol";

interface INexusInterface {
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
        ISSVNetworkCore.Cluster cluster;
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

    event RollupWhitelisted(string name, address rollupAddress);
    event RollupRegistered(address rollupAdmin, address withdrawalAddress);
    event StakingLimitChanged(
        address rollupAdmin,
        uint16 oldStakingLimit,
        uint16 newStakingLimit
    );
    event ValidatorSubmitted(Validator[] validators, address rolupAdmin);
    event ValidatorShareSubmitted(bytes pubKey, address rolupAdmin);
    event ClusterAdded(uint64 clusterId, uint64[] operatorIds);
    event SSVRecharged(address sender, uint256 amount);
    event ClusterRecharged(uint64 clusterId,uint256 amount);
    event RollupRewardsUpdated(address admin,uint256 amount,bool slashing);
    event ValidatorExited(address admin,bytes[] publicKeys);

    function depositValidatorRollup(
        address _rollupAdmin,
        Validator[] calldata _validators
    ) external;

    function depositValidatorShares(
        address _rollupAdmin,
        ValidatorShares calldata _validatorShare
    ) external;

}
