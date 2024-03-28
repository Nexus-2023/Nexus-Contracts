//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;
import {Ownable} from "./utils/NexusOwnable.sol";
import {UUPSUpgreadable} from "./utils/UUPSUpgreadable.sol";
import {INodeOperator} from "./interfaces/INodeOperator.sol";

/**
 * @title Nexus Node Operator Contract
 * @author RohitAudit
 * @dev This contract handles the Node Operator operations which includes:
 * 1. Registration of node operators
 * 2. Updation of node operators
 * 3. Creation of SSV clusters
 *
 * In future, we will also introduce scoring in the contract itself.
 */
contract NodeOperator is Ownable, UUPSUpgreadable, INodeOperator{

    // This stores the DKG ip needed for DKG ceremony
    mapping(uint64=>string) public ssvDKGIP;

    // This stores the id of operators in a particular cluster
    mapping (uint64=>uint64[]) public ssvClusters;

    function initialize() public initilizeOnce {
        _ownableInit(msg.sender);
    }

    function updateProxy(address newImplemetation) public onlyOwner {
        updateCodeAddress(newImplemetation);
    }

    /**
     * This function is used to register node operators
     * @param _operator_id: Operator ID as registered with SSV
     * @param _pub_key: Operator public key used for key share creation
     * @param _ip_address: DKG IP used for DKG ceremony
     * @param name: Name of the operator registered with SSV
     */
    function registerSSVOperator(uint64 _operator_id, string calldata _pub_key, string calldata _ip_address, string calldata name) external onlyOwner{
        bytes memory ip = bytes(ssvDKGIP[_operator_id]);
        if (ip.length != 0) revert OperatorAlreadyRegistered();
        ssvDKGIP[_operator_id] = _ip_address;
        emit SSVOperatorRegistered(name,_operator_id,_pub_key,_ip_address);
    }

    /**
     * This function is used to update the DKG IP for node operator
     * @param _operator_id: Operator ID as registered with SSV
     * @param _ip_address: DKG IP used for DKG ceremony
     */
    function updateSSVOperatorIP(uint64 _operator_id,string calldata _ip_address) external onlyOwner{
        bytes memory ip = bytes(ssvDKGIP[_operator_id]);
        if (ip.length == 0) revert OperatorNotRegistered();
        ssvDKGIP[_operator_id] = _ip_address;
        emit SSVOperatorUpdated(_operator_id,_ip_address);
    }

    /**
     * This function is used to create clusters using node operators
     * @param operatorIds: Operator IDs as registered with SSV
     * @param clusterId: Cluster ID associated with the cluster
     */
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

    function getCluster(uint64 clusterId) external override view returns(uint64[] memory){
        if (ssvClusters[clusterId].length == 0) revert ClusterNotPresent();
        return ssvClusters[clusterId];
    }
}