// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.4.21;

import "./TokenWhaleChallenge.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.4.21
///      echidna program-analysis/echidna/exercises/exercise4/template.sol --contract TestToken --test-mode assertion
///      ```
///      or by providing a config
///      ```
///      echidna program-analysis/echidna/exercises/exercise4/template.sol --contract TestToken --config program-analysis/echidna/exercises/exercise4/config.yaml
///      ```
// contract Test is TokenWhaleChallenge {
//     address echidna;
//     event State(uint256 balanceFrom);

//     function TokenWhaleChallenge(msg.sender) public {
//         echidna = msg.sender;
//         //TokenWhaleChallenge(echidna);
//     }

//     function echidna_test_balance() public view returns (bool) {
//         return (balanceOf[echidna] <= 1000);
//     }

//     function transferFrom(address from, address to, uint256 value) public {
//         emit State(balanceOf[from]);
//         super.transferFrom(from, to, value);
//     }
// }
