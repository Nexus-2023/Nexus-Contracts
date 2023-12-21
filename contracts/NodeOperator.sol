//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Ownable} from "./utils/NexusOwnable.sol";
import {Proxiable} from "./utils/UUPSUpgreadable.sol";
import {INodeOperator} from "./interfaces/INodeOperator.sol";

contract NodeOperator is Ownable, Proxiable, INodeOperator{

    mapping(uint64=>string) public ssvDKGIP;
    mapping (uint64=>uint64[]) public ssvClusters;

    function initialize() public initilizeOnce {
        _ownableInit(msg.sender);
    }

    function registerSSVOperator(uint64 _operator_id, string calldata _pub_key, string calldata _ip_address, string calldata name) external onlyOwner{
        bytes memory ip = bytes(ssvDKGIP[_operator_id]);
        if (ip.length != 0) revert OperatorAlreadyRegistered();
        ssvDKGIP[_operator_id] = _ip_address;
        emit SSVOperatorRegistered(name,_operator_id,_pub_key,_ip_address);
    }

    function updateSSVOperatorIP(uint64 _operator_id,string calldata _ip_address) external onlyOwner{
        bytes memory ip = bytes(ssvDKGIP[_operator_id]);
        if (ip.length == 0) revert OperatorNotRegistered();
        ssvDKGIP[_operator_id] = _ip_address;
    }

    function addCluster(
        uint64[] calldata operatorIds,
        uint64 clusterId
    ) external onlyOwner {
        if (ssvClusters[clusterId].length != 0) revert ClusterAlreadyExited();
        for (uint256 i=0;i<operatorIds.length;i++){
            bytes memory ip = bytes(ssvDKGIP[operatorIds[i]]);
            if (ip.length == 0) revert OperatorNotRegistered();
        }
        ssvClusters[clusterId] = operatorIds;
        emit ClusterAdded(clusterId, operatorIds);
    }

    function getCluster(uint64 clusterId) external view returns(uint64[] memory){
        return ssvClusters[clusterId];
    }
}