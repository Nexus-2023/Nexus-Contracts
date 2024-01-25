//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {NexusBaseBridge} from "./NexusBaseBridge.sol";

/**
 * @title Nexus Bridge User C value Contract
 * @author RohitAudi
 * @dev This contract is used to distribute the rewards back to the users by changing the
 * token value depending on the rewards earned.
 */
abstract contract NexusBridgeUserCValue is NexusBaseBridge {
    uint256 public cValue;
    uint256 public amountDistributed;
    uint256 private constant CValueBasisPoint = 1e18;

    event CValueUpdated(uint256 cValue);

    function updateExitedValidators() external override onlyNexus {
        if((getRewards() - amountDistributed) < VALIDATOR_DEPOSIT) revert ValidatorNotExited();
        validatorCount -= 1;
    }

    function updateCValue() external validNexusFee(NexusFeePercentage){
        uint256 rewards_to_claim = getRewards() - amountDistributed;
        if(rewards_to_claim > VALIDATOR_DEPOSIT) revert WaitingForValidatorExits();
        uint256 _nexus_rewards = (NexusFeePercentage*rewards_to_claim)/BASIS_POINT;
        amountDistributed+=rewards_to_claim-_nexus_rewards;
        cValue = ((amountDeposited - amountWithdrawn)*CValueBasisPoint)/((address(this).balance-_nexus_rewards)+(validatorCount*VALIDATOR_DEPOSIT));
        (bool nexus_success, bytes memory nexus_data) = NEXUS_FEE_ADDRESS.call{
            value: _nexus_rewards,
            gas: 5000
        }("");
        if (nexus_success) {
            emit NexusRewardsRedeemed(_nexus_rewards);
        }
        emit CValueUpdated(cValue);
    }
}