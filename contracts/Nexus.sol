//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Withdraw} from "./Withdrawal.sol";
import {INexusBridge} from "./interfaces/INexusBridge.sol";
import {INodeOperator} from "./interfaces/INodeOperator.sol";
import {Ownable} from "./utils/NexusOwnable.sol";
import {Proxiable} from "./utils/UUPSUpgreadable.sol";
import {ISSVNetworkCore} from "./interfaces/ISSVNetwork.sol";
import {INexusInterface} from "./interfaces/INexusInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BytesArrayLibrary} from "./libraries/BytesArrayLibrary.sol";

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
contract Nexus is INexusInterface, Ownable, Proxiable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using BytesArrayLibrary for bytes[];

    EnumerableSet.AddressSet private whitelistedRollups;
    address public offChainBot = 0x45a3f77543167c8D0965194879c4e0B0dbB581d0;
    mapping(address => Rollup) public rollups;
    bytes[] public depositingPubkeys;
    bytes[] public activePubkeys;
    bytes[] public exitingKeys;
    mapping(uint256=>uint16) polygonCDKPartners;
    address public NodeOperatorContract;

    // change these addresses to mainnet address when deploying on mainnet
    address private constant SSV_NETWORK =
        0xC3CD9A0aE89Fff83b71b58b6512D43F8a41f363D;
    address private constant SSV_TOKEN =
        0x3a9f01091C446bdE031E39ea8354647AFef091E7;
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

    function initialize() public initilizeOnce {
        _ownableInit(msg.sender);

    }

    // admin related functions

    function whitelistRollup(
        string calldata name,
        address rollupAddress
    ) external onlyOwner{
        if (whitelistedRollups.add(rollupAddress)) {
            emit RollupWhitelisted(name, rollupAddress);
        } else {
            revert AddressAlreadyWhitelisted();
        }
    }

    function setOffChainBot(address _botAddress) external onlyOwner {
        offChainBot = _botAddress;
    }

    function updateProxy(address newImplemetation) public onlyOwner {
        updateCodeAddress(newImplemetation);
    }

    function setNodeOperatorContract(address _nodeOperator) external onlyOwner{
        NodeOperatorContract=_nodeOperator;
        emit NodeOperatorContractChanged(_nodeOperator);
    }

    function changeExecutionFeeAddress(address _execution_fee_address) external onlyOwner {
        ISSVNetworkCore(SSV_NETWORK).setFeeRecipientAddress(_execution_fee_address);
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
    ) external onlyWhitelistedRollup{
        if (rollups[msg.sender].bridgeContract != address(0))
            revert RollupAlreadyRegistered();
        if (INexusBridge(bridgeContract).NEXUS_NETWORK()!=address(this)) revert NexusAddressNotFound();
        if (stakingLimit>BASIS_POINT) revert IncorrectStakingLimit();
        INexusBridge(bridgeContract).setNexusFee(nexusFee);
        INodeOperator(NodeOperatorContract).getCluster(operatorCluster);
        rollups[msg.sender] = Rollup(
            bridgeContract,
            stakingLimit,
            operatorCluster
        );
        emit RollupRegistered(msg.sender, bridgeContract,stakingLimit,operatorCluster,nexusFee);
    }

    function changeStakingLimit(
        uint16 newStakingLimit
    ) external onlyWhitelistedRollup {
        rollups[msg.sender].stakingLimit = newStakingLimit;
        emit StakingLimitChanged(
            msg.sender,
            newStakingLimit
        );
    }

    function changeNexusFee(uint256 _new_fee) external onlyWhitelistedRollup{
        INexusBridge(rollups[msg.sender].bridgeContract).setNexusFee(_new_fee);
        emit NexusFeeChanged(msg.sender,_new_fee);
    }

    function changeCluster(uint64 operatorCluster) external onlyWhitelistedRollup{
        INodeOperator(NodeOperatorContract).getCluster(operatorCluster);
        rollups[msg.sender].operatorCluster = operatorCluster;
        emit RollupOperatorClusterChanged(msg.sender,operatorCluster);
    }


    // validator realted function

    function depositValidatorRollup(
        address _rollupAdmin,
        Validator[] calldata _validators
    ) external override onlyOffChainBot {
        INexusBridge(rollups[_rollupAdmin].bridgeContract)
            .depositValidatorNexus(
                _validators,
                uint256(rollups[_rollupAdmin].stakingLimit)
                );
        for (uint i = 0; i < _validators.length; i++) {
            depositingPubkeys.addElement(_validators[i].pubKey);
            emit ValidatorSubmitted(_validators[i].pubKey, _rollupAdmin);
        }
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
        activePubkeys.addElement(_validatorShare.pubKey);
        emit ValidatorShareSubmitted(_validatorShare.pubKey, _rollupAdmin,_validatorShare.amount);
    }

    function validatorExit(address rollupAdmin,bytes[] calldata pubkeys) external onlyOffChainBot{
        for(uint i=0;i<pubkeys.length;i++){
            (bool key_present, uint256 index) = activePubkeys.findElement(pubkeys[i]);
            if (key_present){
                activePubkeys.removeElement(pubkeys[i]);
                exitingKeys.addElement(pubkeys[i]);
                emit ValidatorExitSubmitted(rollupAdmin,pubkeys[i]);
            }else{
                revert InvalidKeySupplied();
            }
        }
    }

    function validatorExitBalanceTransferred(address rollupAdmin,bytes calldata pubkey, uint64[] memory operatorIds, ISSVNetworkCore.Cluster memory cluster) external onlyOffChainBot{
        ISSVNetworkCore(SSV_NETWORK).removeValidator(pubkey, operatorIds, cluster);
        exitingKeys.removeElement(pubkey);
        emit ValidatorExited(rollupAdmin,pubkey);
        INexusBridge(rollups[rollupAdmin].bridgeContract).updateExitedValidators();
    }

    function validatorSlashed(address rollupAdmin, uint256 amountSlashed) external onlyOffChainBot{
        INexusBridge(rollups[rollupAdmin].bridgeContract).validatorsSlashed(amountSlashed);
        emit RollupValidatorSlashed(rollupAdmin,amountSlashed);
    }

    // cluster related functions

    function rechargeCluster(uint64 clusterId, uint256 amount,ISSVNetworkCore.Cluster memory cluster) external onlyOffChainBot{
        ISSVNetworkCore(SSV_NETWORK).deposit(address(this),INodeOperator(NodeOperatorContract).getCluster(clusterId),amount,cluster);
        emit ClusterRecharged(clusterId,amount);
    }
}
