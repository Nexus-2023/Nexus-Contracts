//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INexusBridge {
    function setWithdrawal(address withdrawal_credential) external;

    function validatorExit() external payable;

    function depositValidator(
        bytes calldata pubkey,
        bytes calldata withdrawal_credential,
        bytes calldata signature,
        bytes calldata deposit_root
    ) external;
}
