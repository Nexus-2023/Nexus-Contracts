//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Ownable} from "./utils/NexusOwnable.sol";
/**
 * @title Validator Execution Reward Contract
 * @author RohitAudit
 * @dev This contract handles the proposer awards for the validators. As the rewards are associated with particular
 * validator one needs to update it in the contract as to who can claim those rewards. The reward bot performs that
 * functionality by tracking proposer of the block
 */
contract ValidatorExecutionRewards is Ownable{
    struct RollupExecutionReward{
        address rollupAdmin;
        uint256 amount;
    }
    mapping(address => uint256) public executionRewards;
    address public rewardBot;
    uint256 public rewardsEarned;
    uint256 public rewardsClaimed;
    event ExecutionRewardsReceived(uint256 rewards);
    event ChangeRewardBotAddress(address reward_bot);
    event ExecutionRewardSent(uint256 rewards,address rollupAdmin);
    event RollupExecutionRewardUpdated(address rollupAdmin, uint256 rewards);
    error NotRewardBot();
    error RewardNotPresent();
    error IncorrectRewards();
    error IncorrectAddress();

    modifier onlyRewardBot() {
        if (msg.sender != rewardBot) revert NotRewardBot();
        _;
    }

    constructor(address _rewardBot){
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
    function updateRewardsRollup(RollupExecutionReward[] calldata rewards) external onlyRewardBot {
        uint256 total_rewards;
        for(uint i=0;i<rewards.length;i++){
            executionRewards[rewards[i].rollupAdmin] += rewards[i].amount;
            total_rewards+=rewards[i].amount;
            emit RollupExecutionRewardUpdated(rewards[i].rollupAdmin, rewards[i].amount);
        }
        if (total_rewards>(rewardsEarned-rewardsClaimed)) revert IncorrectRewards();
    }

    /**
     * This function can be used by rollupAdmin to claim the proposer rewards asscociated with their validators
     */
    function claimRewards() external {
        if (executionRewards[msg.sender] == 0) revert RewardNotPresent();
        uint256 amount_to_send = executionRewards[msg.sender];
        rewardsClaimed+=amount_to_send;
        executionRewards[msg.sender] = 0;
        (bool rewardSent,bytes memory data) = msg.sender.call{
            value: amount_to_send,
            gas: 5000
        }("");
        if (rewardSent) emit ExecutionRewardSent(amount_to_send,msg.sender);
    }
}
