//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {BytesArrayLibrary} from "./libraries/BytesArrayLibrary.sol";
import {INexusBridge} from "./interfaces/INexusBridge.sol";

/**
 * @dev
 */
contract Withdraw {
    using BytesArrayLibrary for bytes[];
    address public constant NEXUS_FEE_CONTRACT =
        0x4142676ec5706706D3a0792997c4ea343405376b;
    address public immutable NEXUS_CONTRACT;
    address public immutable DAO_ADDRESS;
    uint16 public nexusShare;
    uint16 constant BASIS_POINT = 10000;
    uint256 public MINIMUM_SLASHED_BALANCE = 16 ether;
    bytes[] public exiting_pubkeys;
    uint256 public amount_slashed;

    // Events
    event SlashingAmountUpdated(uint256 amount);
    event NexusShareUpdated(uint32 new_share);
    event ExitingValidatorAdded(bytes public_key);
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

    constructor(address _dao_address, uint16 _nexus_fee_percentage) {
        DAO_ADDRESS = _dao_address;
        nexusShare = _nexus_fee_percentage;
        NEXUS_CONTRACT = msg.sender;
    }

    function exitInitiated(bytes[] memory pubkeys) external onlyNexus {
        for (uint256 i; i < pubkeys.length; ) {
            exiting_pubkeys.addElement(pubkeys[i]);
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
        (bool rollupSuccess, bytes memory rollupData) = DAO_ADDRESS.call{
            value: amount,
            gas: 5000
        }("");
    }

    function slashing(uint256 slashing_amount) external onlyNexus {
        if (amount_slashed != slashing_amount) {
            amount_slashed = slashing_amount;
            emit SlashingAmountUpdated(slashing_amount);
        }
    }

    function updateNexusRewards(uint16 _new_fee) external onlyNexus {
        nexusShare = _new_fee;
        emit NexusShareUpdated(_new_fee);
    }
}
