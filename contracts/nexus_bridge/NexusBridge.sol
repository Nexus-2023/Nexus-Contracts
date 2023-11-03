//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {INexusBridge} from "./INexusBridge.sol";
import {IDepositContract} from "./IDepositContract.sol";
import {INexusInterface} from "./INexusInterface.sol";

/**
 * @title Nexus Bridge Contract
 * @dev This contract is used to enable eth staking via native bridge ontract of any rollup. It
 * enables the integration with Nexus Network. It also gives permission to Nexus contract to submit
 * keys using the unique withdrawal credentials for rollup.
 *
 * The staking ratio is maintained by the Nexus Contract and is set during the registration.It
 * can be changed anytime by rollup while doing a transaction to the Nexus Contract.
 */
abstract contract NexusBridge is INexusBridge {
    // To be changed to the respective network addresses:
    address public constant DEPOSIT_CONTRACT =
        0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
    // to be changed rollup DAO
    address public constant DAO = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
    uint256 private constant VALIDATOR_DEPOSIT = 32 ether;
    uint256 private constant BASIS_POINT = 10000;
    address public NEXUS_NETWORK = 0xd1C788Ac548Cb467b3c4B14CF1793BCa3c1dCBEB;
    Rewards public stakingReturns;
    uint256 private lastRewardUpdationTime;

    modifier onlyNexus() {
        if (msg.sender != NEXUS_NETWORK) revert NotNexus();
        _;
    }

    modifier onlyDAO() {
        if (msg.sender != DAO) revert NotDAO();
        _;
    }

    function depositValidatorNexus(
        INexusInterface.Validator[] calldata _validators,
        uint256 stakingLimit,
        uint256 validatorCount
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
    }

    function updateRewards(
        uint256 amount,
        bool slashed,
        uint256 validatorCount
    ) external override onlyNexus {
        if (
            !slashed &&
            amount <
            ((validatorCount *
                (32 ether) *
                (block.timestamp - lastRewardUpdationTime) *
                10) / 31556952) *
                100
        ) revert WrongRewardAmount();
        if (slashed) {
            stakingReturns.Slashing += amount;
        } else {
            stakingReturns.TotalRewardsEarned += amount;
        }
        lastRewardUpdationTime = block.timestamp;
        emit RewardsUpdated(amount, slashed);
    }

    function redeemRewards() external onlyDAO {
        uint256 amount = stakingReturns.TotalRewardsEarned -
            stakingReturns.RewardsRedeemed -
            stakingReturns.Slashing;
        (bool success, bytes memory nexusData) = DAO.call{
            value: amount,
            gas: 5000
        }("");
        stakingReturns.RewardsRedeemed += amount;
        if (success) {
            emit RewardsRedeemed(amount);
        }
    }
}
