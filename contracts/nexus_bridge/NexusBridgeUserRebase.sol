//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {NexusBaseBridge} from "./NexusBaseBridge.sol";

/**
 * @title Nexus Bridge Rebase Contract
 * @dev This contract is used to enable eth staking via native bridge ontract of any rollup. It
 * enables the integration with Nexus Network. It also gives permission to Nexus contract to submit
 * keys using the unique withdrawal credentials for rollup.
 *
 * The staking ratio is maintained by the Nexus Contract and is set during the registration.It
 * can be changed anytime by rollup while doing a transaction to the Nexus Contract.
 */
abstract contract NexusBridgeUserRebase is NexusBaseBridge {
    uint256 public amountDistributed;

    event RebaseAmount(uint256 amount);


    function updateExitedValidators() external override onlyNexus {
        if((getRewards() - amountDistributed) < VALIDATOR_DEPOSIT) revert ValidatorNotExited();
        validatorCount -= 1;
    }

    function rebase() external validNexusFee(NexusFeePercentage) {
        uint256 rewards_to_claim = getRewards() - amountDistributed;
        if(rewards_to_claim > VALIDATOR_DEPOSIT) revert WaitingForValidatorExits();
        uint256 _nexus_rewards = (NexusFeePercentage*rewards_to_claim)/BASIS_POINT;
        (bool nexus_success, bytes memory nexus_data) = NEXUS_FEE_ADDRESS.call{
            value: _nexus_rewards,
            gas: 5000
        }("");
        if (nexus_success) {
            emit NexusRewardsRedeemed(_nexus_rewards);
        }
        amountDistributed+=rewards_to_claim-_nexus_rewards;
        emit RebaseAmount(rewards_to_claim - _nexus_rewards);
    }
}