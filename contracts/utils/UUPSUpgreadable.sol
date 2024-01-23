//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Proxiable
 * @author RohitAudit
 * @dev This contract is implemented in the implementation contract to make it upgreadable. Removing this contract
 * will remove the upgreadability feature of the contract
 */
contract UUPSUpgreadable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    bytes32 constant IMPLEMENTATION_SLOT = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    error NotCompatible();
    function updateCodeAddress(address newAddress) internal {
        if(bytes32(IMPLEMENTATION_SLOT) != UUPSUpgreadable(newAddress).proxiableUUID()) revert NotCompatible();
        assembly { // solium-disable-line
            sstore(IMPLEMENTATION_SLOT, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return IMPLEMENTATION_SLOT;
    }
}
