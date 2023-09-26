//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISSVNetworkCore} from "../interfaces/ISSVNetwork.sol";
 
contract SSVContract is ISSVNetworkCore{


    function registerValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        bytes calldata sharesEncrypted,
        uint256 amount,
        Cluster memory cluster
    ) external override {
        
    }

    function removeValidator(bytes calldata publicKey, uint64[] memory operatorIds, Cluster memory cluster) external override {

    }

}