//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {NexusBridgeDAO} from "../nexus_bridge/NexusBridgeDAO.sol";

contract BridgeContract is NexusBridgeDAO {
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
