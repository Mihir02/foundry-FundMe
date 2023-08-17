// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // int256 num = 1;
    FundMe fundMe;

    address USER = makeAddr("tessa");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // num = 2;
        // fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);

    }

    function testMinimumDollarIsFive() public {
        // console.log("Hello World");
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPrcieFeedVersion() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // next line should revert!!!
        fundMe.fund(); // send 0 value
    }

    function testFundUpdatesFundedDS() public {
        vm.prank(USER); // The next TXN will be from USER

        fundMe.fund{value: SEND_VALUE}();
        uint256 amtfunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amtfunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOffFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        // vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testWithdrawFailsIfNotOwner() public funded {
        vm.prank(USER);
        vm.expectRevert(); // next line should revert!!!
        // The next TXN will be from USER either way as vm will skip other vm calls
        fundMe.withdraw();

    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBal = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // Assert
        uint256 endingOwnerBal = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBal, startingOwnerBal + startingFundMeBalance);

    }
    function testWithdrawFromMultipleFunders() public funded{
        uint160 noOfFunders = 10;
        uint160 startingFunderIndex = 2;

        for(uint160 i = startingFunderIndex; i < noOfFunders; i++){
            
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBal = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;


        // uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // uint256 gasEnd = gasleft();

        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log("Gas Used: ", gasUsed);

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBal == fundMe.getOwner().balance);
        
    }

    function testWithdrawFromMultipleFundersCheap() public funded{
        uint160 noOfFunders = 10;
        uint160 startingFunderIndex = 2;

        for(uint160 i = startingFunderIndex; i < noOfFunders; i++){
            
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBal = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;


        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // uint256 gasEnd = gasleft();

        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log("Gas Used: ", gasUsed);

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBal == fundMe.getOwner().balance);
        
    }


}
