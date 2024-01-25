//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {BytesArrayLibrary} from "./libraries/BytesArrayLibrary.sol";
import {INexusBridge} from "./interfaces/INexusBridge.sol";

/**
 *
 * @dev
 */
contract Withdraw {
    using BytesArrayLibrary for bytes[];
    address public constant NEXUS_FEE_CONTRACT =
        0x4142676ec5706706D3a0792997c4ea343405376b;
    address public immutable NEXUS_CONTRACT;
    address public immutable DAO_ADDRESS;
    uint16 public nexusShare;
    uint16 public constant BASIS_POINT = 10000;
    uint256 public minimumSlashedAmount = 16 ether;
    bytes[] public exitingPubkeys;
    uint256 public amountSlashed;

    // Events
    event SlashingAmountUpdated(uint256 amount);
    event NexusShareUpdated(uint32 newShare);
    event ExitingValidatorAdded(bytes publicKey);
    event NexusRewardSent(uint256 amount);
    event RollupRewardSent(uint256 amount);

    // Errors
    error InvalidAccess();
    modifier onlyNexus() {
        if (msg.sender != NEXUS_CONTRACT) {
            revert InvalidAccess();
        }
        _;
    }

    constructor(address _daoAddress, uint16 _nexusFeePercentage) {
        DAO_ADDRESS = _daoAddress;
        nexusShare = _nexusFeePercentage;
        NEXUS_CONTRACT = msg.sender;
    }

    function exitInitiated(bytes[] memory pubkeys) external onlyNexus {
        for (uint256 i; i < pubkeys.length; ) {
            exitingPubkeys.addElement(pubkeys[i]);
            emit ExitingValidatorAdded(pubkeys[i]);
            unchecked {
                ++i;
            }
        }
    }

    function withdrawRewards(bytes[] memory pubkeys) external onlyNexus {
        if (pubkeys.length == 0) {
            _sendRewards(address(this).balance);
        } else {}
    }

    function _sendRewards(uint256 amount) internal {
        uint256 amountNexus = (nexusShare * amount) / BASIS_POINT;
        uint256 amountDAO = amount - amountNexus;
        (bool rollupSuccess, bytes memory rollupData) = DAO_ADDRESS.call{
            value: amountDAO,
            gas: 5000
        }("");
        if (rollupSuccess) emit RollupRewardSent(amountDAO);

        (bool nexusSuccess, bytes memory nexusData) = NEXUS_FEE_CONTRACT.call{
            value: amountNexus,
            gas: 5000
        }("");
        if (nexusSuccess) emit NexusRewardSent(amountNexus);
    }

    function _sendBridge(uint256 amount) internal {
    }

    function slashing(uint256 slashingAmount) external onlyNexus {
        if (amountSlashed != slashingAmount) {
            amountSlashed = slashingAmount;
            emit SlashingAmountUpdated(slashingAmount);
        }
    }

    function updateNexusRewards(uint16 _newFee) external onlyNexus {
        nexusShare = _newFee;
        emit NexusShareUpdated(_newFee);
    }
}
