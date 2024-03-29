//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;
import {IDepositContract} from "../interfaces/IDepositContract.sol";
import {INexusInterface} from "../interfaces/INexusInterface.sol";
import {INexusBridge} from "../interfaces/INexusBridge.sol";

/**
 * @title Nexus Bridge Contract
 * @author RohitAudit
 * @dev This contract is used to enable eth staking via native bridge ontract of any rollup. It
 * enables the integration with Nexus Network. It also gives permission to Nexus contract to submit
 * keys using the unique withdrawal credentials for rollup.
 *
 * The staking ratio is maintained by the Nexus Contract and is set during the registration.It
 * can be changed anytime by rollup while doing a transaction to the Nexus Contract.
 */
abstract contract NexusBaseBridge is INexusBridge {
    address public override NEXUS_NETWORK =
        0xd1C788Ac548Cb467b3c4B14CF1793BCa3c1dCBEB;
    address public NEXUS_FEE_ADDRESS =
        0x735bf02E4435dFADfE47a5FE5FBD42Ef375864A9;
    uint256 public amountDeposited;
    uint256 public amountWithdrawn;
    uint256 public slashedAmount;
    // todo: validator exit variable to be stored if possible
    uint256 public override validatorCount;
    uint256 public override NexusFeePercentage;
    // To be changed to the respective network addresses:
    address public constant DEPOSIT_CONTRACT =
        0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;

    uint256 public constant VALIDATOR_DEPOSIT = 32 ether;
    uint256 public constant BASIS_POINT = 10000;
    error NotNexus();
    error IncorrectWithdrawalCredentials();
    error StakingLimitExceeding();
    error IncorrectNexusFee();
    error ValidatorNotExited();
    error WaitingForValidatorExits();

    event SlashingUpdated(uint256 amount);
    event NexusFeeChanged(uint256 _nexus_fee);
    event NexusRewardsRedeemed(uint256 amount);

    modifier onlyNexus() {
        if (msg.sender != NEXUS_NETWORK) revert NotNexus();
        _;
    }

    modifier validNexusFee(uint256 _nexus_fee) {
        if (
            _nexus_fee > (BASIS_POINT) / 10 || _nexus_fee <= (BASIS_POINT) / 16
        ) revert IncorrectNexusFee();
        _;
    }

    function setNexusFee(
        uint256 _nexus_fee
    ) external override onlyNexus validNexusFee(_nexus_fee) {
        NexusFeePercentage = _nexus_fee;
        emit NexusFeeChanged(_nexus_fee);
    }

    function depositValidatorNexus(
        INexusInterface.Validator[] calldata _validators,
        uint256 stakingLimit
    ) external override onlyNexus {
        uint256 validators_balance = (validatorCount +
            _validators.length) *
            (VALIDATOR_DEPOSIT);
        if ((( validators_balance*BASIS_POINT) /
            (address(this).balance + validators_balance)) > stakingLimit)
            revert StakingLimitExceeding();
        for (uint i = 0; i < _validators.length; i++) {
            bytes memory withdrawalFromCred = _validators[i]
                .withdrawalAddress[12:];
            if (
                keccak256(withdrawalFromCred) !=
                keccak256(abi.encodePacked(address(this)))
            ) revert IncorrectWithdrawalCredentials();
            IDepositContract(DEPOSIT_CONTRACT).deposit{
                value: VALIDATOR_DEPOSIT
            }(
                _validators[i].pubKey,
                _validators[i].withdrawalAddress,
                _validators[i].signature,
                _validators[i].depositRoot
            );
        }
        validatorCount += _validators.length;
    }

    function validatorsSlashed(uint256 amount) external override onlyNexus {
        slashedAmount = amount;
        emit SlashingUpdated(amount);
    }

    function getRewards() public view returns (uint256) {
        return
            (address(this).balance + (validatorCount * VALIDATOR_DEPOSIT)) -
            (amountDeposited - amountWithdrawn) -
            slashedAmount;
    }
}
