// SPDX-License-Identifier: MIT

/*
 * @audit-qa [QA-01]
 * Description: Floating Pragma Solidity Version could lead to a potential vulnerability.
 * Attack Vector: Uncontroled version.
 * Mitigation: Set the solidity version
 */
pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@solidity-campaignable/Campaignable.sol";

interface IERC721Contract {
    function earlyMint(address to, uint8 quantity, uint256 campaignId) external payable;
}

contract EarlyMint is ReentrancyGuard, Ownable, Campaignable {
    ///////////////////////////////
    //   State Variables        //
    /////////////////////////////
    /*
     * @audit-qa [QA-03]
     * Description: Private variables cost less gass than public.
     * Attack Vector: Gas saving.
     * Mitigation: Make vars private and create getters.
     *
     * @audit-qa [QA-07]
     * Description: variables above are all explicitly set to 0 when that is already their default value
     * Variables affected:
     * campaignCounter
     * i loop counters, campaignCounter, exists
     */

    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public campaignCounter = 0;
    address public authorizerAddress;
    mapping(uint256 => Campaign) public campaignList;
    mapping(uint256 => mapping(address => uint8)) public paidOrders;
    mapping(uint256 => address[]) public paidOrdersAddresses;

    /////////////////////////
    //   Modifiers        //
    ///////////////////////

    /*
     * @audit-high [H-01]
     * Description: For loop with campaignList[i].externalId maybe lead to out of gas.
     * Attack Vector: Dos
     * Mitigation: Store each externalId in a mapping and create a require.
     * require(campaignsByExternalId[keccak256(abi.encodePacked(_externalId))] == 0, "xxx");
     */

    modifier ensureUniqueCampaignExternalId(string memory _externalId) {
        for (uint256 i = 0; i < campaignCounter; i++) {
            require(
                keccak256(abi.encodePacked(campaignList[i].externalId)) != keccak256(abi.encodePacked(_externalId)),
                "External ID already exists"
            );
        }
        _;
    }

    /////////////////////////
    //   Functions        //
    ///////////////////////
    /*
     * @audit-qa [QA-02]
     * Description: Consider declaring functions as external.
     * Attack Vector: Gas saving.
     * Mitigation: Make functions external instead of public.
     *
     *
     * @audit-qa [QA-04]
     * Description: Consider the use of the OZ Access Control Library to create profiles.
     * Attack Vector: NA.
     * Mitigation: NA.
     *
     * @audit-qa [QA-08]
     * Description: Using memory for read-only parameters.
     * Attack Vector: Save gas.
     * Mitigation: use calldata instead of memory.
     * Functions affected: createCampaign(), getCampaignByExternalId()
     * executeMintForCampaigns(), reserveOrder()
     *
     */
    constructor() {
        authorizerAddress = msg.sender;
    }

    ////////////////////////////////
    //   Public Functions        //
    ////////////////////////////////
    /*
     * @audit-qa [QA-05]
     * Description: Use ++variable rather than variable++ to save gass.
     * Attack Vector: Gas saving.
     * Affected functions:
     * ensureUniqueCampaignExternalId(), createCampaign(),
     * executeMintForCampaign(), executeMintForCampaigns(),
     * addPaidOrdersAddress(), getMyCampaignIDs(), getCampaignsManagedByAddress().
     *
     * @audit-qa [QA-06]
     * Description: Repeated access to loop break condition.
     * Mitigation: Store the length of the arrays in memory before the loop.
     * Affected functions:
     * executeMintForCampaign() executeMintForCampaigns() addPaidOrdersAddress()
     */

    function updateAuthorizerAddress(address _authorizerAddress) public onlyOwner {
        authorizerAddress = _authorizerAddress;
    }

    /*
     * @audit-low [L-03]
     * Description: transfer() to transfer ETH.
     * Attack Vector: Out of gas.
     * Mitigation: Use call instead.
     * (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
     * require(success, "Transfer failed.");
     *
     * @audit-low [L-04]
     * Description: Not follow CEI pattern.
     * Attack Vector: Reentrancy.
     * Mitigation: Follow the pattern.
     */
    function requestRefund(uint256 _campaignId) public nonReentrant {
        Campaign storage campaign = campaignList[_campaignId];
        uint8 walletOrders = paidOrders[_campaignId][msg.sender];
        require(campaign.minted == false, "This campaign has already been minted");
        require(walletOrders > 0, "You don't hold any orders in this campaign");
        uint256 refundAmount = walletOrders * campaign.price;
        payable(msg.sender).transfer(refundAmount);
        campaign.ordersTotal -= walletOrders;
        campaign.campaignBalance -= refundAmount;
        paidOrders[_campaignId][msg.sender] = 0;
        emit OrderRefunded(
            Order({
                campaignId: _campaignId,
                purchaserAddress: msg.sender,
                quantity: walletOrders,
                campaignOrdersTotal: campaign.ordersTotal,
                walletOrdersTotal: 0,
                externalId: campaign.externalId
            })
        );
    }

    /*
     * @audit-low [L-02]
     * Description: An user use the same signature for a multiple actions
     * Attack Vector: NA.
     * Mitigation: Add a nonce to the signature.
     * Notes: also affect to reserveOrder() function.
     */
    function createCampaign(Campaign memory _campaign, bytes memory _signature)
        public
        isValidCreate(_signature, _campaign.externalId, _campaign.fee, address(this), authorizerAddress)
        ensureUniqueCampaignExternalId(_campaign.externalId)
        nonReentrant
        returns (uint256)
    {
        require(_campaign.ordersPerWallet > 0, "You must allow at least 1 order per wallet");
        require(_campaign.maxOrders > 0, "You must allow at least 1 order");
        require(_campaign.paymentAddress != address(0), "NFT contract address cannot be 0x0");

        campaignList[campaignCounter] = Campaign({
            id: campaignCounter,
            externalId: _campaign.externalId,
            creator: _campaign.creator,
            paymentAddress: _campaign.paymentAddress,
            minted: false,
            fee: _campaign.fee,
            price: _campaign.price,
            maxOrders: _campaign.maxOrders,
            ordersTotal: 0,
            ordersPerWallet: _campaign.ordersPerWallet,
            campaignBalance: 0
        });
        emit CampaignCreated(campaignList[campaignCounter]);
        campaignCounter++;
        return campaignCounter - 1;
    }

    /*
     * @audit-medium [M-01]
     * Description: Inconsistencies in the database.
     * Attack Vector: Could create campaigns with the deleted externalId.
     * Mitigation: Delete the entire info associated to a campaign.
     */
    function deleteCampaign(uint256 _campaignId) public onlyOwner {
        delete campaignList[_campaignId];
    }

    /*
     * @audit-issue [M-02]
     * Description: Inconsistencies in the database.
     * Attack Vector: Steal funds.
     * Mitigation: Control the balances in case execution of this function.
     */
    function setUnMinted(uint256 _campaignId) public onlyOwner {
        campaignList[_campaignId].minted = false;
    }

    /*
     * @audit-high [H-04]
     * Description: Malicious Campaign Creator could steal funds.
     * Attack Vector: Steal funds.
     * Mitigation: More control over the address (maybe with the signature).
     */
    function updatePaymentAddress(uint256 _campaignId, address _paymentAddress) public {
        require(_paymentAddress != address(0), "Contract address cannot be 0");
        require(
            campaignList[_campaignId].creator == msg.sender || msg.sender == owner(),
            "You must be the creator of this campaign to update the address"
        );
        campaignList[_campaignId].paymentAddress = _paymentAddress;
    }

    /*
     * @audit-qa [QA-09]
     * Description: Use a Pointer instead of accessing mapping multiple times and cache values when possible.
     * Attack Vector: Gas.
     * Mitigation: Declare a storage pointer to the Campaign struct from campaignList instead of accessing it multiple times repeatedly.
     * Campaign storage campaign = campaignList[_campaignId];
     */
    function executeMintForCampaigns(uint256[] memory _campaignIds) public nonReentrant {
        for (uint256 i = 0; i < _campaignIds.length; i++) {
            executeMintForCampaign(_campaignIds[i]);
        }
    }

    /*
     * @audit-high [H-03]
     * Description: If _requestedOrderQuantity == 0 could lead to out of gas.
     * Attack Vector: Dos
     * Mitigation: Fix the reserveOrder() function to revert if _requestedOrderQuantity is 0.
     * 
     * @audit-qa [QA-10]
     * Description: Accepts overpayment.
     */
    function reserveOrder(uint256 _campaignId, uint8 _requestedOrderQuantity, bytes memory _signature)
        public
        payable
        isValidReserve(_signature, _campaignId, address(this), authorizerAddress)
    {
        Campaign storage campaign = campaignList[_campaignId];
        uint256 totalPrice = campaignList[_campaignId].price * _requestedOrderQuantity;
        require(msg.value >= totalPrice, "Not enough ETH sent");
        require(
            paidOrders[_campaignId][msg.sender] + _requestedOrderQuantity <= campaign.ordersPerWallet,
            "You cannot own more than the max orders per wallet"
        );
        require(campaign.maxOrders >= campaign.ordersTotal + _requestedOrderQuantity, "No more orders available");

        paidOrders[_campaignId][msg.sender] += _requestedOrderQuantity;
        uint8 walletOrders = paidOrders[_campaignId][msg.sender];
        addPaidOrdersAddress(_campaignId, msg.sender);
        campaign.ordersTotal += _requestedOrderQuantity;
        campaign.campaignBalance += campaign.price * _requestedOrderQuantity;
        emit OrderCreated(
            Order({
                campaignId: _campaignId,
                purchaserAddress: msg.sender,
                quantity: _requestedOrderQuantity,
                campaignOrdersTotal: campaign.ordersTotal,
                walletOrdersTotal: walletOrders,
                externalId: campaign.externalId
            })
        );
    }

    /*
     * @audit-high [H-05]
     * Description: Update with a wallet that already exist.
     * Attack Vector: Lost of funds
     * Mitigation: More control over the addresses.
     */
    function updateWalletAddress(uint256 _campaignId, address _newAddress) public nonReentrant {
        require(paidOrders[_campaignId][msg.sender] > 0, "You must own at least 1 order to update your address");
        paidOrders[_campaignId][_newAddress] = paidOrders[_campaignId][msg.sender];
        delete paidOrders[_campaignId][msg.sender];
    }

    /*
     * @audit-medium [M-03]
     * Description: Inconsistencies in the database.
     * Attack Vector: Steal funds.
     * Mitigation: Control the balances and fees. Be sure that everybody are aware of the execution.
     */
    function withdraw() public onlyOwner {
        (bool owner,) = payable(owner()).call{value: address(this).balance}("");
        require(owner);
    }

    function withdrawAmount(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Not enough funds");
        (bool owner,) = payable(owner()).call{value: _amount}("");
        require(owner);
    }

    ////////////////////////////////
    //   Internal Functions       //
    ////////////////////////////////

    /*
     * @audit-high [H-02]
     * Description: For loop with paidOrdersAddresses[_campaignId][i] maybe lead to out of gas.
     * Attack Vector: Dos
     * Mitigation: Consider dividing the minting process into batches.
     */
    function executeMintForCampaign(uint256 _campaignId) internal {
        require(
            campaignList[_campaignId].creator == msg.sender || msg.sender == owner(),
            "You must be the creator of this campaign to trigger the mint"
        );
        require(campaignList[_campaignId].minted == false, "This campaign has already been minted");
        require(
            campaignList[_campaignId].paymentAddress != address(0),
            "You must set the address of the mint contract before minting"
        );
        campaignList[_campaignId].minted = true;
        for (uint256 i = 0; i < paidOrdersAddresses[_campaignId].length; i++) {
            address key = paidOrdersAddresses[_campaignId][i];
            uint8 orders = paidOrders[_campaignId][key];
            uint256 value = (orders * campaignList[_campaignId].price)
                - (orders * campaignList[_campaignId].price * campaignList[_campaignId].fee / 100);
            if (orders > 0) {
                IERC721Contract(campaignList[_campaignId].paymentAddress).earlyMint{value: value}(
                    key, orders, _campaignId
                );
            }
        }
    }

    function addPaidOrdersAddress(uint256 _campaignId, address _paidOrdersAddress) internal {
        bool exists = false;
        for (uint256 i = 0; i < paidOrdersAddresses[_campaignId].length; i++) {
            if (paidOrdersAddresses[_campaignId][i] == _paidOrdersAddress) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            paidOrdersAddresses[_campaignId].push(_paidOrdersAddress);
        }
    }

    ///////////////////////////
    //    VIEW FUNCTIONS  /////
    //////////////////////////
    /*
     * @audit-low [L-06]
     * Description: for loop over array could run out of gas.
     * Attack Vector: NA
     * Mitigation: map the campaigns before the loop.
     * Note: Affected fuctions
     * getCampaignByExternalId(), getMyCampaignIDs(), getCampaignsManagedByAddress()
     */

    /*
     * @audit-low [L-05]
     * Description: Non-existant campaign, return 0.
     * Attack Vector: NA
     * Mitigation: check campaign exists.
     */
    function getPriceToReserveOrders(uint256 _campaignId, uint8 _quantity) public view returns (uint256) {
        return campaignList[_campaignId].price * _quantity;
    }

    function getCampaignByExternalId(string memory _externalId) public view returns (Campaign memory) {
        for (uint256 i = 0; i < campaignCounter; i++) {
            if (keccak256(abi.encodePacked(campaignList[i].externalId)) == keccak256(abi.encodePacked(_externalId))) {
                return campaignList[i];
            }
        }
        revert("Campaign not found");
    }

    function getPaymentAddress(uint256 _campaignId) public view returns (address) {
        return campaignList[_campaignId].paymentAddress;
    }

    function getPaidOrdersByCampaignId(uint256 _campaignId) public view returns (address[] memory) {
        return paidOrdersAddresses[_campaignId];
    }

    /*
     * @audit-low [L-01]
     * Description: msg.sender off-chain not verificable.
     * Attack Vector: NA.
     * Mitigation: Use only getCampaignsManagedByAddress().
     */
    function getMyCampaignIDs() public view returns (uint256[] memory) {
        uint256[] memory campaigns = new uint256[](campaignCounter);
        uint256 counter = 0;
        for (uint256 i = 0; i < campaignCounter; i++) {
            if (campaignList[i].creator == msg.sender) {
                campaigns[counter] = i;
                counter++;
            }
        }
        return campaigns;
    }

    function getCampaignsManagedByAddress(address _creator) public view returns (uint256[] memory) {
        uint256[] memory campaigns = new uint256[](campaignCounter);
        uint256 counter = 0;
        for (uint256 i = 0; i < campaignCounter; i++) {
            if (campaignList[i].creator == _creator) {
                campaigns[counter] = i;
                counter++;
            }
        }
        return campaigns;
    }
}
