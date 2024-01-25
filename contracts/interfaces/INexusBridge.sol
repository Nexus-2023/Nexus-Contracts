//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {INexusInterface} from "./INexusInterface.sol";

interface INexusBridge {
    function setNexusFee(uint256 _nexus_fee) external;
    function NEXUS_NETWORK() external view returns (address);
    function validatorCount() external view returns (uint256);
    function NexusFeePercentage() external view returns(uint256);
    function validatorsSlashed(uint256 amount) external;
    function updateExitedValidators() external;
    function depositValidatorNexus(INexusInterface.Validator[] calldata _validators,uint256 stakingLimit) external;
}
