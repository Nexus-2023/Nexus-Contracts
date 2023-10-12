//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {NexusBridge} from "../NexusBridge.sol";

contract BridgeContract is NexusBridge {
    event EthReceived(uint256 amount);

    constructor(address _nexus){
        NEXUS_NETWORK = _nexus;
    }

    receive() external payable {
        emit EthReceived(msg.value);
    }

    function withdraw(uint256 amount) external payable {
        (bool success, bytes memory data) = msg.sender.call{value:amount,gas:5000}("");
    }
}
