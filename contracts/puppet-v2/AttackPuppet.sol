// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";

contract Attack {
    using Address for address;

    address private uniswapRouter;
    address private pool;
    address private weth;
    address private token;
    uint8 private v;
    bytes32 private r;
    bytes32 private s;

    constructor(
        address _uniswapRouter,
        address _pool,
        address _weth,
        address _token,
        uint8 _v,
        bytes32 _r,
        bytes32 _v
    ) payable {
        //permit token
        token.functionStaticCall(abi.encodeWithSignature("balanceOf(address)",msg.sender));

        token.functionCall(
            abi.encodeWithSignature(
                "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)",
                msg.sender,
                address(this),

            )
        );
        //transfer token and eth to this contact
        //swap token to eth
        //deposit and approve weth
        //borrow
        //transfer token to player
    }
}
