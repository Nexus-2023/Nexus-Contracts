//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INexusBridge {
    function setWithdrawal(address withdrawalCredential) external;

    function validatorExit() external payable;

    function depositValidator(
        bytes calldata pubkey,
        bytes calldata withdrawalCredential,
        bytes calldata signature,
        bytes32 depositRoot
    ) external;
}
