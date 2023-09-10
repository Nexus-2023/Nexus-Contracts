//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {NexusBridge} from "../NexusBridge.sol";

contract BridgeContract is NexusBridge {
    event EthReceived(uint256 amount);

    receive() external payable {
        emit EthReceived(msg.value);
    }
}
