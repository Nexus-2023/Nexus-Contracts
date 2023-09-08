//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library BytesArrayLibrary {
    function addElement(bytes[] storage arr, bytes memory data) internal {
        arr.push(data);
    }

    function findElement(
        bytes[] storage arr,
        bytes memory target
    ) internal view returns (bool found, uint256 index) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (keccak256(arr[i]) == keccak256(target)) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function removeElement(bytes[] storage arr, bytes memory target) internal {
        for (uint256 i = 0; i < arr.length; i++) {
            if (keccak256(arr[i]) == keccak256(target)) {
                if (i < arr.length - 1) {
                    arr[i] = arr[arr.length - 1];
                }
                arr.pop();
                return;
            }
        }
    }
}
