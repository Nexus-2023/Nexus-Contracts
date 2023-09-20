//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ISSVNetworkCore} from "./ISSVNetwork.sol";

interface INexusInterface {
    struct Rollup {
        address bridgeContract;
        uint16 stakingLimit;
        address withdrawalAddress;
        uint64 validatorCount;
        uint32 operatorCluster;
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

    error NotNexusBot();
    error AddressAlreadyWhitelisted();
    error AddressNotWhitelisted();
    error RollupAlreadyPresent();
    error RollupAlreadyRegistered();

    event RollupWhitelisted(string name, address rollupAddress);
    event RollupRegistered(address rollupAdmin,address withdrawalAddress);
    event StakingLimitChanged(address rollupAdmin,uint16 oldStakingLimit, uint16 newStakingLimit);
    event ValidatorSubmitted(bytes pubKey, address rolupAdmin);
    event ValidatorShareSubmitted(bytes pubKey, address rolupAdmin);

    function depositValidatorRollup(address _rollupAdmin,Validator[] calldata _validators) external;
    function depositValidatorShares(address _rollupAdmin,ValidatorShares[] calldata _validatorShares) external;
}