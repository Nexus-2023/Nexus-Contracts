//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {INexusInterface} from "./INexusInterface.sol";

interface INexusBridge {
    function setWithdrawal(address withdrawalCredential) external;

    function validatorExit() external payable;

    function depositValidatorNexus(
        INexusInterface.Validator[] calldata _validators,
        uint256 stakingLimit,
        uint256 validatorCount
    ) external;
}
