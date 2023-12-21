//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IDepositContract} from "../interfaces/IDepositContract.sol";
import {INexusInterface} from "../interfaces/INexusInterface.sol";
import {INexusBridge} from "../interfaces/INexusBridge.sol";


/**
 * @title Nexus Bridge Contract
 * @dev This contract is used to enable eth staking via native bridge ontract of any rollup. It
 * enables the integration with Nexus Network. It also gives permission to Nexus contract to submit
 * keys using the unique withdrawal credentials for rollup.
 *
 * The staking ratio is maintained by the Nexus Contract and is set during the registration.It
 * can be changed anytime by rollup while doing a transaction to the Nexus Contract.
 */
abstract contract NexusBridgeDAO is INexusBridge {
    address public override NEXUS_NETWORK = 0xd1C788Ac548Cb467b3c4B14CF1793BCa3c1dCBEB;
    address public NEXUS_FEE_ADDRESS = 0x735bf02E4435dFADfE47a5FE5FBD42Ef375864A9;
    uint256 public amountDeposited;
    uint256 public amountWithdrawn;
    uint256 public slashedAmount;
    uint256 public rewardsClaimed;
    uint256 public validatorCount;
    uint256 public NexusFeePercentage;
    // To be changed to the respective network addresses:
    address public constant DEPOSIT_CONTRACT = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
    // to be changed rollup DAO
    address public constant DAO = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
    uint256 private constant VALIDATOR_DEPOSIT = 32 ether;
    uint256 private constant BASIS_POINT = 10000;
    error NotNexus();
    error NotDAO();
    error IncorrectWithdrawalCredentials();
    error StakingLimitExceeding();
    error IncorrectNexusFee();
    error WaitingForValidatorExits();
    error ValidatorNotExited();

    event SlashingUpdated(uint256 amount);
    event NexusRewardsRedeemed(uint256 amount);
    event RewardsRedeemed(uint256 amount);
    event NexusFeeChanged(uint256 _nexus_fee);


    modifier onlyNexus() {
        if (msg.sender != NEXUS_NETWORK) revert NotNexus();
        _;
    }

    modifier onlyDAO() {
        if (msg.sender != DAO) revert NotDAO();
        _;
    }

    function setNexusFee(uint256 _nexus_fee) external override onlyNexus{
        if(_nexus_fee>(BASIS_POINT)/10) revert IncorrectNexusFee();
        NexusFeePercentage = _nexus_fee;
        emit NexusFeeChanged(_nexus_fee);
    }

    function depositValidatorNexus(
        INexusInterface.Validator[] calldata _validators,
        uint256 stakingLimit
    ) external override onlyNexus {
        for (uint i = 0; i < _validators.length; i++) {
            bytes memory withdrawalFromCred = _validators[i]
                .withdrawalAddress[12:];
            if (
                keccak256(withdrawalFromCred) !=
                keccak256(abi.encodePacked(address(this)))
            ) revert IncorrectWithdrawalCredentials();
        }
        if (
            (((validatorCount + _validators.length) *
                (VALIDATOR_DEPOSIT) *
                BASIS_POINT) /
                (address(this).balance +
                    (validatorCount + _validators.length) *
                    (VALIDATOR_DEPOSIT))) > stakingLimit
        ) revert StakingLimitExceeding();

        for (uint i = 0; i < _validators.length; i++) {
            IDepositContract(DEPOSIT_CONTRACT).deposit{
                value: VALIDATOR_DEPOSIT
            }(
                _validators[i].pubKey,
                _validators[i].withdrawalAddress,
                _validators[i].signature,
                _validators[i].depositRoot
            );
        }
        validatorCount+=_validators.length;
    }

    function validatorsSlashed(
        uint256 amount
    ) external override onlyNexus {
        slashedAmount = amount;
        emit SlashingUpdated(amount);
    }

    function getPendingRewards() public view returns(uint256){
        return (address(this).balance+(validatorCount*VALIDATOR_DEPOSIT)) - (amountDeposited - amountWithdrawn) - slashedAmount;
    }

    function updateExitedValidators(uint256 exitedValidator) external override onlyNexus {
        if(getPendingRewards() < VALIDATOR_DEPOSIT) revert ValidatorNotExited();
        validatorCount -= exitedValidator;
    }

    function redeemRewards(address reward_account) external onlyDAO {
        uint256 total_rewards = getPendingRewards();
        if(total_rewards > VALIDATOR_DEPOSIT) revert WaitingForValidatorExits();
        uint256 _nexus_rewards = (NexusFeePercentage*total_rewards)/BASIS_POINT;
        (bool nexus_success, bytes memory nexus_data) = NEXUS_FEE_ADDRESS.call{
            value: _nexus_rewards,
            gas: 5000
        }("");
        if (nexus_success) {
            emit NexusRewardsRedeemed(_nexus_rewards);
        }
        (bool dao_success, bytes memory dao_data) = reward_account.call{
            value: (total_rewards - _nexus_rewards),
            gas: 5000
        }("");
        rewardsClaimed += total_rewards;
        if (dao_success) {
            emit RewardsRedeemed((total_rewards - _nexus_rewards));
        }
    }
}
