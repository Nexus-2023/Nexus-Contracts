//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {NexusBridgeUserCValue} from "../nexus_bridge/NexusBridgeUserCValue.sol";

contract BridgeContractCValue is NexusBridgeUserCValue {
    event EthReceived(uint256 amount);

    constructor(
        address _nexus,
        uint256 _amountDeposited,
        uint256 _amountWithdrawn,
        uint256 _slashedAmount,
        uint256 _amountDistributed,
        uint256 _validatorCount,
        uint256 _NexusFeePercentage
    ) {
        NEXUS_NETWORK = _nexus;
        amountDeposited = _amountDeposited;
        amountWithdrawn = _amountWithdrawn;
        slashedAmount = _slashedAmount;
        amountDistributed = _amountDistributed;
        validatorCount = _validatorCount;
        NexusFeePercentage = _NexusFeePercentage;
    }

    receive() external payable {
        emit EthReceived(msg.value);
    }

    function withdraw(uint256 amount) external payable {
        (bool success, bytes memory data) = msg.sender.call{
            value: amount,
            gas: 5000
        }("");
    }
}
