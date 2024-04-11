// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {IStaking721Mock} from "./interface/IStaking721Mock.sol";
import {Staking721Test} from "./Staking721.t.sol";
import {DefaultStaking721Impl} from "./implementation/DefaultStaking721.sol";

contract DefaultStaking721Test is Staking721Test {
    function createStaking721() public override returns (IStaking721Mock) {
        return new DefaultStaking721Impl(address(erc721), address(erc20));
    }

    function withdrawAll(uint256[] memory tokenIds) public override {
        staking721.withdraw(tokenIds);
    }
}
