//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
interface INodeOperator {

    error ClusterAlreadyExited();
    error OperatorNotRegistered();
    error OperatorAlreadyRegistered();
    event ClusterAdded(uint64 clusterId, uint64[] operatorIds);
    event SSVOperatorRegistred(uint256 indexed operatorId, string pubKey, string ip_address);

}