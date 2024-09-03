// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address immutable i_user;

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    constructor() {
        i_user = makeAddr("defaultUser");
    }

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();

        fundMe = deployFundMe.run();

        vm.deal(i_user, STARTING_BALANCE);
    }

    modifier funded() {
        vm.prank(i_user);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.getMinimumUSD(), 5 * 10 ** 18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), address(msg.sender));
    }

    function testGetPriceVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundSucceedsWithEnoughEth() public funded {
        uint256 amountFunded = fundMe.getAddresToAmountFunded(i_user);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFunderToArrayOfFunders() public funded {
        address actual_funder = fundMe.getFunder(0);
        assertEq(actual_funder, i_user);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(i_user);
        vm.expectRevert();

        fundMe.withdraw();
    }

    function testWithDrawWithSingleFunder() public funded {
        // Arrange Act Assert pattern.

        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithDrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);

            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }
}
