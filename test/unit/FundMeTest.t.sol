// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //setup function always runs first and write it first in order always
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        // assertEq(fundMe.i_owner(), msg.sender); // us->FundMeTest->fundMe
        // assertEq(fundMe.i_owner(), address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // What can we do to work with addresses outside our system ?
    // 1. Unit -> testing specific part of code
    // 2. Integration -> testing how our code works with other parts of our code
    // 3. Forked -> Testing our code in a simulated real environment
    // 4. Staging -> Testing our code in a real environment that is not production
    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    // few commands :
    // forge coverage --fork-url $SEPOLIA_RPC_URL
    // forge test --mt testPriceFeedVersionIsAccurate -vvv --fork-url $SEPOLIA_RPC_URL

    // we want to make our code more robust.
    // no hardcoding addresses
    // make the code modular

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // next line should fail. If next line does not fail this will fail and this test will fail
        fundMe.fund(); // sends 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // next transaction will be send by user (which we set up)
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayofFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // act
        //uint256 gasStart = gasleft();   // 1000 // it tells how much gas is left in your transaction call ? 
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());    // 200
        fundMe.withdraw();
        //uint256 gasEnd = gasleft();     // 1000-200 = 800
        //uint256 gasUsed = (gasStart - gasEnd)*tx.gasprice; 

        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // arrange 
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // not 0 bcs then in for loop address(0) might cause some problem
        
        // basically by for loop we are funding the fundMe with multiple funders
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank and vm.deal both together are done in hoax
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }


        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance); 
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // arrange 
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // not 0 bcs then in for loop address(0) might cause some problem
        
        // basically by for loop we are funding the fundMe with multiple funders
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank and vm.deal both together are done in hoax
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }


        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance); 
    }
}
