// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Dex.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.4.21
///      echidna program-analysis/echidna/exercises/exercise4/template.sol --contract TestToken --test-mode assertion
///      ```
///      or by providing a config
///      ```
///      echidna program-analysis/echidna/exercises/exercise4/template.sol --contract TestToken --config program-analysis/echidna/exercises/exercise4/config.yaml
///      ```
contract Test {
    Dex dex;
    SwappableToken token1;
    SwappableToken token2;

    constructor () {
        dex = new Dex();
        token1 = new SwappableToken(address(dex),"T1", "T1", 110 ether);
        token1.transfer(address(dex), 100 ether);
        token2 = new SwappableToken(address(dex),"T2", "T2", 110 ether);
        token2.transfer(address(dex), 100 ether);
        dex.setTokens(address(token1), address(token2));
        dex.renounceOwnership();
    }

    function approveDex(uint256 amount) public {
        dex.approve(address(dex), amount);
    }

    function swap(bool direction, uint amount_) public {
        uint256 balance;
        if (direction) {
            balance = token1.balanceOf(address(this));
        } else {
            balance = token2.balanceOf(address(this));
        }
        uint256 amount;
        if (balance == 0) {
            amount = 0;
        } else {
            amount = amount_ % balance;
        }

        if (direction) {
            dex.swap(address(token1), address(token2), amount);
        } else {
            dex.swap(address(token2), address(token1), amount);
        }
    }

    function echidna_has_balance1_gte_50() public view returns (bool) {
        return token1.balanceOf(address(dex)) >= 50 ether;
    }

    function echidna_has_balance2_gte_50() public view returns (bool) {
        return token2.balanceOf(address(dex)) >= 50 ether;
    }

    function echidna_has_balance1_gte_20() public view returns (bool) {
        return token1.balanceOf(address(dex)) >= 20 ether;
    }

    function echidna_has_balance2_gte_20() public view returns (bool) {
        return token2.balanceOf(address(dex)) >= 20 ether;
    }

    function echidna_has_balance1_gte_5() public view returns (bool) {
        return token1.balanceOf(address(dex)) >= 5 ether;
    }

    function echidna_has_balance2_gte_5() public view returns (bool) {
        return token2.balanceOf(address(dex)) >= 5 ether;
    }
}
