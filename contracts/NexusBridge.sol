//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Nexus Bridge Contract
 * @dev This contract is used to enable eth staking via native bridge ontract of any rollup. It
 * enables the integration with Nexus Network. It also gives permission to Nexus contract to submit
 * keys using the unique withdrawal credentials for rollup.
 *
 * The staking ratio is maintained by the Nexus Contract and is set during the registration.It
 * can be changed anytime by rollup while doing a transaction to the Nexus Contract.
 */
abstract contract NexusBridge {
    // To be changed to the respective network addresses:
    address public constant DEPOSIT_CONTRACT =
        0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
    address public constant NEXUS_NETWORK =
        0x5DfFeE1B9C7D68726545c3e05fB99ACc6660aC05;
    address public withdrawalCrendentails;
    uint256 public constant VALIDATOR_DEPOSIT = 32 ether;

    error NotNexus();
    error IncorrectWithdrawalAddress();
    error ValidatorDepositFailed();
    error WithdrawalAddressExists();
    error IncorrectWithdrawalCredentials();

    event ValidatorExitReceived(uint256 amount);

    modifier onlyNexus() {
        if (msg.sender != NEXUS_NETWORK) revert NotNexus();
        _;
    }

    modifier onlyWithdrawal() {
        if (msg.sender != withdrawalCrendentails)
            revert IncorrectWithdrawalAddress();
        _;
    }

    function setWithdrawal(address _withdrawalCredentials) external onlyNexus {
        if (withdrawalCrendentails != address(0))
            revert WithdrawalAddressExists();
        withdrawalCrendentails = _withdrawalCredentials;
    }

    function depositValidator(
        bytes calldata pubkey,
        bytes calldata withdrawalCredential,
        bytes calldata signature,
        bytes calldata depositRoot
    ) external onlyNexus {
        // if (keccak256(abi.encodePacked(withdrawal_credential)) != keccak256(abi.encodePacked(WITHDRAWAL_CREDENTAILS))) revert IncorrectWithdrawalCredentials();
        (bool success, bytes memory data) = DEPOSIT_CONTRACT.call{
            value: VALIDATOR_DEPOSIT
        }(
            abi.encodeWithSignature(
                "deposit(bytes,bytes,bytes,bytes32)",
                pubkey,
                withdrawalCredential,
                signature,
                depositRoot
            )
        );
        if (!success) {
            revert ValidatorDepositFailed();
        }
    }

    function validatorExit() external payable onlyWithdrawal {
        emit ValidatorExitReceived(msg.value);
    }
}
