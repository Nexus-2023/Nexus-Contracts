//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Withdraw} from "./Withdrawal.sol";
import {INexusBridge} from "./interfaces/INexusBridge.sol";
import {Ownable} from "./utils/NexusOwnable.sol";
import {Proxiable} from "./utils/UUPSUpgreadable.sol";
import {ISSVNetworkCore} from "./interfaces/ISSVNetwork.sol";
import {INexusInterface} from "./interfaces/INexusInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BytesArrayLibrary} from "./libraries/BytesArrayLibrary.sol";

/**
 * @title Nexus Core Contract
 * @dev This contract is heart and soul of Nexus Network and is used for Operations like
 * 1. Onboarding of rollup to Nexus Network
 * 2. Change in staking limit for rollup
 * 3. Whitelisting rollup address
 * 4. Submitting keys to rollup bridge
 * 5. Submitting keyshares to SSV contract
 * 6. Recharge funds in SSV contract for validator operation
 * 7. Reward distribution for rollup to DAO and Nexus Fee Contract
 */
contract Nexus is INexusInterface, Ownable, Proxiable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using BytesArrayLibrary for bytes[];

    EnumerableSet.AddressSet private whitelistedRollups;
    address public offChainBot;
    mapping(address => Rollup) public rollups;
    mapping(uint32 => uint32[]) public operatorClusters;
    bytes[] public depositingPubkeys;

    // change these addresses to mainnet address when deploying on mainnet
    address private constant SSV_NETWORK =
        0xC3CD9A0aE89Fff83b71b58b6512D43F8a41f363D;
    address private constant SSV_TOKEN =
        0x3a9f01091C446bdE031E39ea8354647AFef091E7;

    modifier onlyOffChainBot() {
        if (msg.sender != offChainBot) revert NotNexusBot();
        _;
    }

    modifier onlyWhitelistedRollup() {
        if (!whitelistedRollups.contains(msg.sender))
            revert AddressNotWhitelisted();
        _;
    }

    function initialize() public initilizeOnce {
        _ownableInit(msg.sender);
    }

    function isRollupWhitelisted(
        address rollupAddress
    ) external view returns (bool) {
        return whitelistedRollups.contains(rollupAddress);
    }

    function updateProxy(address newImplemetation) public onlyOwner {
        updateCodeAddress(newImplemetation);
    }

    function registerRollup(
        address bridgeContract,
        uint32 operatorCluster,
        uint16 stakingLimit
    ) external onlyWhitelistedRollup {
        if (rollups[msg.sender].bridgeContract != address(0))
            revert RollupAlreadyRegistered();
        rollups[msg.sender] = Rollup(
            bridgeContract,
            stakingLimit,
            0,
            operatorCluster
        );
        emit RollupRegistered(msg.sender,bridgeContract);
    }

    function changeStakingLimit(
        uint16 newStakingLimit
    ) external onlyWhitelistedRollup {
        rollups[msg.sender].stakingLimit = newStakingLimit;
        emit StakingLimitChanged(
            msg.sender,
            rollups[msg.sender].stakingLimit,
            newStakingLimit
        );
    }

    function setOffChainBot(address _botAddress) external onlyOwner {
        offChainBot = _botAddress;
    }

    function depositValidatorRollup(
        address _rollupAdmin,
        Validator[] calldata _validators
    ) external override onlyOffChainBot {
        INexusBridge(rollups[_rollupAdmin].bridgeContract)
            .depositValidatorNexus(
                _validators,
                uint256(rollups[_rollupAdmin].stakingLimit),
                uint256(rollups[_rollupAdmin].validatorCount)
            );
        rollups[_rollupAdmin].validatorCount += uint64(_validators.length);
        for (uint i = 0; i < _validators.length; i++) {
            depositingPubkeys.addElement(_validators[i].pubKey);
        }
        emit ValidatorSubmitted(_validators, _rollupAdmin);
    }

    function depositValidatorShares(
        address _rollupAdmin,
        ValidatorShares calldata _validatorShare
    ) external override onlyOffChainBot {
        (bool key_present, uint256 index) = depositingPubkeys.findElement(
            _validatorShare.pubKey
        );
        if (!key_present) revert KeyNotDeposited();
        IERC20(SSV_TOKEN).approve(SSV_NETWORK, _validatorShare.amount);
        ISSVNetworkCore(SSV_NETWORK).registerValidator(
            _validatorShare.pubKey,
            _validatorShare.operatorIds,
            _validatorShare.sharesEncrypted,
            _validatorShare.amount,
            _validatorShare.cluster
        );
        depositingPubkeys.removeElement(_validatorShare.pubKey);
        emit ValidatorShareSubmitted(_validatorShare.pubKey, _rollupAdmin);
    }

    function whitelistRollup(
        string calldata name,
        address rollupAddress
    ) external onlyOwner {
        if (whitelistedRollups.contains(rollupAddress))
            revert AddressAlreadyWhitelisted();
        if (whitelistedRollups.add(rollupAddress)) {
            emit RollupWhitelisted(name, rollupAddress);
        } else {
            revert RollupAlreadyPresent();
        }
    }
}
