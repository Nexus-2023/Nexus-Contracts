//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Proxy Contract
 * @author RohitAudit
 * @dev This is the UUPS proxy contract on which the transactions are sent
 */

contract Proxy{
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    error ConstructorFailed();
    constructor(bytes memory constructData, address contractLogic) {
        // save the code address
        setImplementation(contractLogic);
        (bool success, bytes memory data ) = contractLogic.delegatecall(constructData); // solium-disable-line
        if (!success) revert ConstructorFailed();
    }

    function setImplementation(address implementation) internal {
        assembly {
            sstore(IMPLEMENTATION_SLOT, implementation)
        }
    }

    function getImplementation() external view returns (address) {
        address impl;
        assembly {
            impl := sload(IMPLEMENTATION_SLOT)
        }
        return impl;
    }

    receive() external payable {
        _proxy_call();
    }

    fallback() external payable {
        _proxy_call();
    }

    function _proxy_call() internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                sload(IMPLEMENTATION_SLOT),
                0x0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}