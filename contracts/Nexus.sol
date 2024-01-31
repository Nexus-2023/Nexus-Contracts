//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {INexusBridge} from "./interfaces/INexusBridge.sol";
import {INodeOperator} from "./interfaces/INodeOperator.sol";
import {Ownable} from "./utils/NexusOwnable.sol";
import {UUPSUpgreadable} from "./utils/UUPSUpgreadable.sol";
import {ISSVNetworkCore} from "./interfaces/ISSVNetwork.sol";
import {INexusInterface} from "./interfaces/INexusInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BytesArrayLibrary} from "./libraries/BytesArrayLibrary.sol";
import "hardhat/console.sol";

/**
 * @title Nexus Core Contract
 * @author RohitAudit
 * @dev This contract is heart and soul of Nexus Network and is used for Operations like
 * 1. Onboarding of rollup to Nexus Network
 * 2. Change parameters for rollup
 * 3. Whitelisting rollup address
 * 4. Submitting keys to rollup bridge
 * 5. Submitting keyshares to SSV contract
 * 6. Recharge funds in SSV contract for validator operation
 * 7. Keep track of validator status and exits
 */
contract Nexus is INexusInterface, Ownable, UUPSUpgreadable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using BytesArrayLibrary for bytes[];
    EnumerableSet.AddressSet private whitelistedRollups;
    address public offChainBot;
    mapping(address => Rollup) public rollups;
    mapping(bytes => ValidatorStatus) public validators;
    mapping(uint256 => uint16) polygonCDKPartners;
    address public NodeOperatorContract;

    // Goerli Address
    // address private constant SSV_NETWORK =
    //     0xC3CD9A0aE89Fff83b71b58b6512D43F8a41f363D;
    // address private constant SSV_TOKEN =
    //     0x3a9f01091C446bdE031E39ea8354647AFef091E7;

    // Holesky Address
    address private constant SSV_NETWORK =
        0x38A4794cCEd47d3baf7370CcC43B560D3a1beEFA;
    address private constant SSV_TOKEN =
        0xad45A78180961079BFaeEe349704F411dfF947C6;
    uint16 private constant BASIS_POINT = 10000;

    modifier onlyOffChainBot() {
        if (msg.sender != offChainBot) revert NotNexusBot();
        _;
    }

    modifier onlyWhitelistedRollup() {
        if (!whitelistedRollups.contains(msg.sender))
            revert AddressNotWhitelisted();
        _;
    }

    modifier nonZeroAddress(address _contract) {
        if (_contract == address(0)) revert IncorrectAddress();
        _;
    }

    function initialize() public initilizeOnce {
        _ownableInit(msg.sender);
    }

    // admin related functions

    function whitelistRollup(
        string calldata name,
        address rollupAddress
    ) external onlyOwner {
        if (whitelistedRollups.add(rollupAddress)) {
            emit RollupWhitelisted(name, rollupAddress);
        } else {
            revert AddressAlreadyWhitelisted();
        }
    }

    function setOffChainBot(
        address _botAddress
    ) external onlyOwner nonZeroAddress(_botAddress) {
        offChainBot = _botAddress;
    }

    function updateProxy(
        address newImplemetation
    ) public onlyOwner nonZeroAddress(newImplemetation) {
        updateCodeAddress(newImplemetation);
    }

    function setNodeOperatorContract(
        address _nodeOperator
    ) external onlyOwner nonZeroAddress(_nodeOperator) {
        NodeOperatorContract = _nodeOperator;
        emit NodeOperatorContractChanged(_nodeOperator);
    }

    function changeExecutionFeeAddress(
        address _execution_fee_address
    ) external onlyOwner nonZeroAddress(_execution_fee_address) {
        ISSVNetworkCore(SSV_NETWORK).setFeeRecipientAddress(
            _execution_fee_address
        );
    }

    // rollup related functions

    function isRollupWhitelisted(
        address rollupAddress
    ) external view returns (bool) {
        return whitelistedRollups.contains(rollupAddress);
    }

    function registerRollup(
        address bridgeContract,
        uint64 operatorCluster,
        uint256 nexusFee,
        uint16 stakingLimit
    ) external onlyWhitelistedRollup {
        if (rollups[msg.sender].bridgeContract != address(0))
            revert RollupAlreadyRegistered();
        if (INexusBridge(bridgeContract).NEXUS_NETWORK() != address(this))
            revert NexusAddressNotFound();
        if (stakingLimit > BASIS_POINT) revert IncorrectStakingLimit();
        INexusBridge(bridgeContract).setNexusFee(nexusFee);
        INodeOperator(NodeOperatorContract).getCluster(operatorCluster);
        rollups[msg.sender] = Rollup(
            bridgeContract,
            stakingLimit,
            operatorCluster
        );
        emit RollupRegistered(
            msg.sender,
            bridgeContract,
            stakingLimit,
            operatorCluster,
            nexusFee
        );
    }

    function changeStakingLimit(
        uint16 newStakingLimit
    ) external onlyWhitelistedRollup {
        if (newStakingLimit > BASIS_POINT) revert IncorrectStakingLimit();
        rollups[msg.sender].stakingLimit = newStakingLimit;
        emit StakingLimitChanged(msg.sender, newStakingLimit);
    }

    function changeNexusFee(uint256 _new_fee) external onlyWhitelistedRollup {
        INexusBridge(rollups[msg.sender].bridgeContract).setNexusFee(_new_fee);
        emit NexusFeeChanged(msg.sender, _new_fee);
    }

    function changeCluster(
        uint64 operatorCluster
    ) external onlyWhitelistedRollup {
        INodeOperator(NodeOperatorContract).getCluster(operatorCluster);
        rollups[msg.sender].operatorCluster = operatorCluster;
        emit RollupOperatorClusterChanged(msg.sender, operatorCluster);
    }

    // validator realted function

    function depositValidatorRollup(
        address _rollupAdmin,
        Validator[] calldata _validators
    ) external override onlyOffChainBot {
        for (uint i = 0; i < _validators.length; i++) {
            if (validators[_validators[i].pubKey] != ValidatorStatus.INACTIVE)
                revert IncorrectValidatorStatus();
            validators[_validators[i].pubKey] = ValidatorStatus.DEPOSITED;
            emit ValidatorSubmitted(_validators[i].pubKey, _rollupAdmin);
        }
        INexusBridge(rollups[_rollupAdmin].bridgeContract)
            .depositValidatorNexus(
                _validators,
                uint256(rollups[_rollupAdmin].stakingLimit)
            );
    }

    function depositValidatorShares(
        address _rollupAdmin,
        ValidatorShares calldata _validatorShare
    ) external override onlyOffChainBot {
        if (validators[_validatorShare.pubKey] != ValidatorStatus.DEPOSITED)
            revert IncorrectValidatorStatus();
        IERC20(SSV_TOKEN).approve(SSV_NETWORK, _validatorShare.amount);
        ISSVNetworkCore(SSV_NETWORK).registerValidator(
            _validatorShare.pubKey,
            _validatorShare.operatorIds,
            _validatorShare.sharesEncrypted,
            _validatorShare.amount,
            _validatorShare.cluster
        );
        validators[_validatorShare.pubKey] = ValidatorStatus.SHARE_DEPOSITED;
        emit ValidatorShareSubmitted(
            _validatorShare.pubKey,
            _rollupAdmin,
            _validatorShare.amount
        );
    }

    function validatorExit(
        address rollupAdmin,
        bytes calldata pubkey,
        uint64[] calldata operatorIds
    ) external onlyOffChainBot {
        if (validators[pubkey] != ValidatorStatus.SHARE_DEPOSITED) revert IncorrectValidatorStatus();
        ISSVNetworkCore(SSV_NETWORK).exitValidator(pubkey, operatorIds);
        validators[pubkey] = ValidatorStatus.VALIDATOR_EXIT_SUBMITTED;
        emit ValidatorExitSubmitted(rollupAdmin, pubkey);
    }

    function validatorExitBalanceTransferred(
        address rollupAdmin,
        bytes calldata pubkey,
        uint64[] memory operatorIds,
        ISSVNetworkCore.Cluster memory cluster
    ) external onlyOffChainBot {
        if (validators[pubkey] != ValidatorStatus.VALIDATOR_EXIT_SUBMITTED)
            revert IncorrectValidatorStatus();
        ISSVNetworkCore(SSV_NETWORK).removeValidator(
            pubkey,
            operatorIds,
            cluster
        );
        INexusBridge(rollups[rollupAdmin].bridgeContract)
            .updateExitedValidators();
        validators[pubkey] = ValidatorStatus.VALIDATOR_EXITED;
        emit ValidatorExited(rollupAdmin, pubkey);
    }

    function validatorSlashed(
        address rollupAdmin,
        uint256 amountSlashed
    ) external onlyOffChainBot {
        INexusBridge(rollups[rollupAdmin].bridgeContract).validatorsSlashed(
            amountSlashed
        );
        emit RollupValidatorSlashed(rollupAdmin, amountSlashed);
    }

    // cluster related functions

    function rechargeCluster(
        uint64 clusterId,
        uint256 amount,
        ISSVNetworkCore.Cluster memory cluster
    ) external onlyOffChainBot {
        ISSVNetworkCore(SSV_NETWORK).deposit(
            address(this),
            INodeOperator(NodeOperatorContract).getCluster(clusterId),
            amount,
            cluster
        );
        emit ClusterRecharged(clusterId, amount);
    }
}
