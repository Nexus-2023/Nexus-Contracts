//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Ownable {
    address private owner;
    bool private initialized = false;

    event OwnerChanged(address oldOwner, address newOwner);
    error NotOwner();
    error ContractAlreadyInitialized();
    modifier onlyOwner() {
        if (msg.sender == owner) revert NotOwner();
        _;
    }

    modifier initilizeOnce() {
        if (initialized) revert ContractAlreadyInitialized();
        _;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function _ownableInit(address _owner) internal {
        owner = _owner;
        initialized = true;
    }

    function transferOwnership(address newOwner) external onlyOwner{
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }
}
