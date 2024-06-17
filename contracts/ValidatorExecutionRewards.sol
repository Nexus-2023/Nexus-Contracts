//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Ownable} from "./utils/NexusOwnable.sol";
import {INexusBridge} from "./interfaces/INexusBridge.sol";

/**
 * @title Validator Execution Reward Contract
 * @author RohitAudit
 * @dev This contract handles the proposer awards for the validators. As the rewards are associated with particular
 * validator one needs to update it in the contract as to who can claim those rewards. The reward bot performs that
 * functionality by tracking proposer of the block
 */
contract ValidatorExecutionRewards is Ownable{
    struct RollupExecutionReward{
        address bridgeAddress;
        uint256 amount;
    }
    address public rewardBot;
    uint256 public rewardsEarned;
    uint256 public rewardsClaimed;
    event ExecutionRewardsReceived(uint256 rewards);
    event ChangeRewardBotAddress(address rewardBot);
    event ExecutionRewardSent(uint256 rewards,address bridgeAddress);
    error NotRewardBot();
    error IncorrectRewards();

    modifier onlyRewardBot() {
        if (msg.sender != rewardBot) revert NotRewardBot();
        _;
    }

    constructor(address _rewardBot){
        if (_rewardBot == address(0)) revert IncorrectAddress();

        rewardBot = _rewardBot;
        emit ChangeRewardBotAddress(_rewardBot);
        _ownableInit(msg.sender);
    }

    function changeRewardBotAddress(address _bot_address) external onlyOwner{
        if (_bot_address == address(0)) revert IncorrectAddress();
        rewardBot = _bot_address;
        emit ChangeRewardBotAddress(_bot_address);
    }

    receive() external payable {
        rewardsEarned+=msg.value;
        emit ExecutionRewardsReceived(msg.value);
    }

    /**
     * Used for updation of rewards for a particular rollup
     * @param rewards: Array of rollups and their rewards earned by their validators
     */
    function transferRewardRollup(RollupExecutionReward[] calldata rewards) external onlyRewardBot {
        uint256 total_rewards;
        for(uint i=0;i<rewards.length;i++){
            INexusBridge(rewards[i].bridgeAddress).recieveExecutionRewards{value:rewards[i].amount}(rewards[i].amount);
            total_rewards+=rewards[i].amount;
            emit ExecutionRewardSent(rewards[i].amount,rewards[i].bridgeAddress);
        }
        if (total_rewards>(rewardsEarned-rewardsClaimed)) revert IncorrectRewards();
    }
}
