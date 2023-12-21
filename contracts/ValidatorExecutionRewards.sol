//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ValidatorExecutionRewards {
    struct RollupExecutionReward{
        address rollupAdmin;
        uint256 amount;
    }
    mapping(address => uint256) public executionRewards;
    address public immutable rewardBot;
    uint256 public rewardsEarned;
    uint256 public rewardsClaimed;
    event ExecutionRewardsReceived(uint256 rewards);
    event ExecutionRewardSent(uint256 rewards,address rollupAdmin);
    event RollupExecutionRewardUpdated(address rollupAdmin, uint256 rewards);
    error NotRewardBot();
    error RewardNotPresent();
    error IncorrectRewards();

    modifier onlyRewardBot() {
        if (msg.sender != rewardBot) revert NotRewardBot();
        _;
    }

    constructor(address _rewardBot){
        rewardBot = _rewardBot;
    }

    receive() external payable {
        rewardsEarned+=msg.value;
        emit ExecutionRewardsReceived(msg.value);
    }

    function updateRewardsRollup(RollupExecutionReward[] calldata rewards) external onlyRewardBot {
        uint256 total_rewards;
        for(uint i=0;i<rewards.length;i++){
            executionRewards[rewards[i].rollupAdmin] += rewards[i].amount;
            total_rewards+=rewards[i].amount;
            emit RollupExecutionRewardUpdated(rewards[i].rollupAdmin, rewards[i].amount);
        }
        if (total_rewards>(rewardsEarned-rewardsClaimed)) revert IncorrectRewards();
    }

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
