//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;
interface INodeOperator {

    error ClusterAlreadyExited();
    error OperatorNotRegistered();
    error OperatorAlreadyRegistered();
    error ClusterNotPresent();
    event ClusterAdded(uint64 clusterId, uint64[] operatorIds);
    event SSVOperatorRegistered(string name,uint256 indexed operatorId, string pubKey, string ip_address);
    event SSVOperatorUpdated(uint64 _operator_id,string _ip_address);

    function getCluster(uint64 clusterId) external view returns(uint64[] memory);
}