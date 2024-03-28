//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;
import {ISavingsDai} from "../interfaces/ISavingsDai.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
}
/**
 * @title Nexus DAI contract
 * @author RohitAudit
 * @dev
 */
abstract contract NexusDai {
    uint256 public DAIDeposited;
    uint256 public DAIRedeemed;

    address public constant sDAI = 0xD8134205b0328F5676aaeFb3B2a0DC15f4029d8C;
    address public constant DAO = 0x14630e0428B9BbA12896402257fa09035f9F7447;
    address public constant DAI = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844;
    error NotDAO();

    event DAIDepositedEvent(uint256 amount);
    event DAIWithdrawnEvent(uint256 amount);
    event DAIRewardsClaimed(uint256 amount);
    modifier onlyDAO() {
        if (msg.sender != DAO) revert NotDAO();
        _;
    }

    function depositDai(uint256 amountSave) internal {
        IERC20(DAI).approve(sDAI, amountSave);
        ISavingsDai(sDAI).deposit(amountSave, address(this));
        DAIDeposited += amountSave;
        emit DAIDepositedEvent(amountSave);
    }

    function removeDai(address user, uint256 amountRedeem) internal {
        ISavingsDai(sDAI).withdraw(amountRedeem, user, address(this));
        DAIRedeemed -= amountRedeem;
        emit DAIWithdrawnEvent(amountRedeem);
    }

    function claimRewardsDAI(address address_to_send) external onlyDAO {
        uint256 amount_to_claim = ISavingsDai(sDAI).maxWithdraw(address(this)) -
            (DAIDeposited - DAIRedeemed);
        ISavingsDai(sDAI).withdraw(
            amount_to_claim,
            address_to_send,
            address(this)
        );
        emit DAIRewardsClaimed(amount_to_claim);
    }
}
