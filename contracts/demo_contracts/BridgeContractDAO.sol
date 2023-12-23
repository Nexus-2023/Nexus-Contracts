//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {NexusBridgeDAO} from "../nexus_bridge/NexusBridgeDAO.sol";

contract BridgeContractDAO is NexusBridgeDAO {
    event EthReceived(uint256 amount);

    constructor(
        address _nexus,
        uint256 _amountDeposited,
        uint256 _amountWithdrawn,
        uint256 _slashedAmount,
        uint256 _rewardsClaimed,
        uint256 _validatorCount,
        uint256 _NexusFeePercentage
    ) {
        NEXUS_NETWORK = _nexus;
        amountDeposited = _amountDeposited;
        amountWithdrawn = _amountWithdrawn;
        slashedAmount = _slashedAmount;
        rewardsClaimed = _rewardsClaimed;
        validatorCount = _validatorCount;
        NexusFeePercentage = _NexusFeePercentage;
    }

    receive() external payable {
        emit EthReceived(msg.value);
    }

    function withdraw(uint256 amount) external payable {
        (bool success, bytes memory data) = msg.sender.call{value:amount,gas:5000}("");
    }
}
