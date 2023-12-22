//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {NexusBaseBridge} from "./NexusBaseBridge.sol";

/**
 * @title Nexus Bridge Contract
 * @dev This contract is used to enable eth staking via native bridge ontract of any rollup. It
 * enables the integration with Nexus Network. It also gives permission to Nexus contract to submit
 * keys using the unique withdrawal credentials for rollup.
 *
 * The staking ratio is maintained by the Nexus Contract and is set during the registration.It
 * can be changed anytime by rollup while doing a transaction to the Nexus Contract.
 */
abstract contract NexusBridgeDAO is NexusBaseBridge {
    uint256 public rewardsClaimed;
    // to be changed rollup DAO
    address public constant DAO = 0x14630e0428B9BbA12896402257fa09035f9F7447;
    event RewardsRedeemed(uint256 amount);
    error NotDAO();

    modifier onlyDAO() {
        if (msg.sender != DAO) revert NotDAO();
        _;
    }

    function updateExitedValidators() external override onlyNexus {
        if(getRewards() < VALIDATOR_DEPOSIT) revert ValidatorNotExited();
        validatorCount -= 1;
    }

    function redeemRewards(address reward_account) external onlyDAO {
        uint256 total_rewards = getRewards();
        if(total_rewards > VALIDATOR_DEPOSIT) revert WaitingForValidatorExits();
        uint256 _nexus_rewards = (NexusFeePercentage*total_rewards)/BASIS_POINT;
        (bool nexus_success, bytes memory nexus_data) = NEXUS_FEE_ADDRESS.call{
            value: _nexus_rewards,
            gas: 5000
        }("");
        if (nexus_success) {
            emit NexusRewardsRedeemed(_nexus_rewards);
        }
        (bool dao_success, bytes memory dao_data) = reward_account.call{
            value: (total_rewards - _nexus_rewards),
            gas: 5000
        }("");
        rewardsClaimed += total_rewards;
        if (dao_success) {
            emit RewardsRedeemed((total_rewards - _nexus_rewards));
        }
    }
}
