//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract NexusRewards {
    event ExecutionRewardsReceived(uint256 rewards);
    event ExecutionRewardSent(uint256 rewards);
    event RollupExecutionRewardUpdated(address rollupAdmin, uint256 rewards);
    error NotRewardBot();
    error RewardNotPresent();
    mapping(address => uint256) executionRewards;
    address public immutable rewardBot;

    modifier onlyRewardBot() {
        if (msg.sender != rewardBot) revert NotRewardBot;
        _;
    }

    construtor(address _rewardBot){
        rewardBot = _rewardBot;
    }

    receive() external payable {
        emit ExecutionRewardsReceived(msg.value);
    }

    function updateRewardsRollup(
        uint256 rewardsEarned,
        address rollupAdmin
    ) external onlyRewardBot {
        executionRewards[rollupAdmin] += rewardsEarned;
        emit RollupExecutionRewardUpdated(rollupAdmin, rewardsEarned);
    }

    function claimRewards() external {
        if (executionRewards[msg.sender] == 0) revert RewardNotPresent();
        executionRewards[msg.sender] == 0;
        (bool rewardSent,_) = DAO_ADDRESS.call{
            value: executionRewards[msg.sender],
            gas: 5000
        }("");
        if (rewardSent) emit ExecutionRewardSent(amountNexus);
    }
}
