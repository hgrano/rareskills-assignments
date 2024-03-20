// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {IStaking721Mock} from "./interface/IStaking721Mock.sol";
import {Staking721Test} from "./Staking721.t.sol";
import {OptimizedStaking721Impl} from "./implementation/OptimizedStaking721.sol";

contract OptimizedStaking721Test is Staking721Test {
    function createStaking721() public override returns (IStaking721Mock) {
        return new OptimizedStaking721Impl(address(erc721), address(erc20));
    }
}
