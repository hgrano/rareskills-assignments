pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import "../src/Denial.sol";

contract DenialTest is Test {
    Denial public denial;

    function setUp() public {
        denial = new Denial();
        (bool ok,) = address(denial).call{value: 10 ether}("");
        require(ok);
    }

    function testAttack() public {
        DenialAttacker attacker = new DenialAttacker();
        denial.setWithdrawPartner(address(attacker));
        denial.withdraw{gas: 1e6}();
    }
}