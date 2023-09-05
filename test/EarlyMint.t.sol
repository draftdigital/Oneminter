// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title EarlyMint.sol audit contract
 * @author Aitor Zaldua
 * @notice
 */

/*
 *
 * //// FUNCTIONS /////
 * constructor                     DONE
 * updateAuthorizerAddress         DONE
 * requestRefund
 * createCampaign                  DONE
 * deleteCampaign
 * setUnMinted
 * updatePaymentAddress            DONE
 * executeMintForCampaign
 * executeMintForCampaigns
 * addPaidOrdersAddress
 * reserveOrder
 * updateWalletAddress
 * withdraw                         DONE
 * withdrawAmount                   DONE
 * getPriceToReserveOrders
 * getCampaignByExternalId
 * getPaymentAddress
 * getPaidOrdersByCampaignId
 * getMyCampaignIDs
 * getCampaignsManagedByAddress
 *
 */

import {Test, console} from "forge-std/Test.sol";
import {EarlyMint} from "../src/EarlyMint.sol";
import "@solidity-campaignable/Campaignable.sol";

contract EarlyMintTest is Test {
    EarlyMint earlyMint;

    address DEPLOYER = makeAddr("deployer");
    address USER1 = makeAddr("user1");

    function setUp() external {
        vm.prank(DEPLOYER);
        earlyMint = new EarlyMint();
    }

    function test001GetLogs() external view {
        console.log("address target contract:   ", address(earlyMint));
        console.log("address test contract:     ", address(this));
        console.log("address authorizerAddress: ", address(earlyMint.authorizerAddress()));
        console.log("address owner:             ", address(earlyMint.owner()));
        console.log("address deployer:          ", DEPLOYER);
        console.log("address USER1:             ", USER1);
    }

    /*
     * Function: constructor()
     * Functionality: Set the owner as msg.sender
     * Parameters: None
     * Requires: None
     * Updates: authorizerAddress
     * Calls: No
     */

    function test002InitialAuthorizerAddressIsTheDeployer() external {
        assertEq(address(earlyMint.owner()), address(earlyMint.authorizerAddress()));
    }

    /*
     * Function: updateAuthorizerAddress()
     * Functionality: Set a new authorizerAddress
     * Parameters: new address for authorizerAddress
     * Requires: onlyOwner
     * Updates: authorizerAddress
     * Calls: No
     */

    // Test 01: owner changes current authorizerAddress for USER1
    function test003UpdateAuthorizerAddressSuceed() external {
        vm.prank(DEPLOYER);
        earlyMint.updateAuthorizerAddress(USER1);
        assertEq(USER1, earlyMint.authorizerAddress());
    }

    // Test 02: USER1 fails to changes current authorizerAddress for USER1
    function test004UpdateAuthorizerAddressFail() external {
        vm.prank(USER1);
        vm.expectRevert();
        earlyMint.updateAuthorizerAddress(USER1);
    }

    /*
     * Function: createCampaign()
     * Functionality: Create a new Campaing and store the struct
     * Parameters: new address for authorizerAddress
     * Requires: onlyOwner
     * Updates: authorizerAddress
     * Calls: No
     */

    function test005CreateCampaing2() external {
        vm.startPrank(DEPLOYER);
        console.log("counter: ", earlyMint.campaignCounter());
        earlyMint.createCampaign3(earlyMint.CreateCampaing2());
        console.log("counter: ", earlyMint.campaignCounter());
        vm.stopPrank();
    }

    /*
     * Function: requestRefund()
     * Functionality: Set the owner as msg.sender
     * Parameters: None
     * Requires: None
     * Updates: authorizerAddress
     * Calls: No
     */
}
