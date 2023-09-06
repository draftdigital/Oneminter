# TABLE OF CONTENTS

- [TABLE OF CONTENTS](#table-of-contents)
- [One Minter](#one-minter)
  - [Invoice: SLOC: 391 - Audit Cost: $2360](#invoice-sloc-391---audit-cost-2360)
  - [How it works](#how-it-works)
  - [ERC721A](#erc721a)
- [VULNERABILITIES](#vulnerabilities)
  - [High](#high)
    - [\[H-01\] For loop in ensureUniqueCampaignExternalId() could lead to a DoS attack](#h-01-for-loop-in-ensureuniquecampaignexternalid-could-lead-to-a-dos-attack)
    - [\[H-02\] For loop in executeMintForCampaign() could lead to a DoS attack](#h-02-for-loop-in-executemintforcampaign-could-lead-to-a-dos-attack)
    - [\[H-03\] Not checking \_requestedOrderQuantity != 0 could lead to a DoS attack](#h-03-not-checking-_requestedorderquantity--0-could-lead-to-a-dos-attack)
  - [\[H-03\] Malicious Campaign Creator can steal funds instead of minting NFTs passively or by frontrunning](#h-03-malicious-campaign-creator-can-steal-funds-instead-of-minting-nfts-passively-or-by-frontrunning)
  - [Medium](#medium)
  - [Low](#low)
  - [QA](#qa)
    - [\[QA-01\] Floating Pragma Solidity Version could lead to a potential vulnerability](#qa-01-floating-pragma-solidity-version-could-lead-to-a-potential-vulnerability)
    - [\[QA-02\] Consider declaring functions as `external`](#qa-02-consider-declaring-functions-as-external)
    - [\[QA-03\] Private variables cost less gass than public](#qa-03-private-variables-cost-less-gass-than-public)
    - [\[QA-04\] Use of the Open Zeppelin Access Control Library to create profiles](#qa-04-use-of-the-open-zeppelin-access-control-library-to-create-profiles)
    - [\[QA-05\] Use ++variable rather than variable++ to save gass](#qa-05-use-variable-rather-than-variable-to-save-gass)
    - [\[QA-06\] Repeated access to loop break condition](#qa-06-repeated-access-to-loop-break-condition)
    - [\[QA-07\] Unnecesary variable initialization](#qa-07-unnecesary-variable-initialization)
    - [\[QA-08\] Using `memory` for read-only parameters](#qa-08-using-memory-for-read-only-parameters)
    - [\[QA-09\] Use a Pointer instead of accessing mapping multiple times and cache values when possible](#qa-09-use-a-pointer-instead-of-accessing-mapping-multiple-times-and-cache-values-when-possible)
    - [\[QA-10\] `reserveOrder()` accepts overpayment](#qa-10-reserveorder-accepts-overpayment)

# One Minter

One Minter is the opportunity for Projects to gather funds in advance. Our software will be a step forward in the investment options

## Invoice: SLOC: 391 - Audit Cost: $2360

## How it works

1.- The Project manager creates a campaign through our front end. They have been pre-approved by our team based on their user account on our web2 side of things.

2.- When they are approved, our API generates their \_signature that will be used in the function call to createCampaign. the campaign is created on-chain. (the user does not see much of this process, it is automatic).

3.- Users who want to "early mint" will also use their user account on our web2 front end.

4.- Users will also be approved by our system to buy a spot in the respective campaign with a similar \_signature process.

5.- Projects can have multiple campaigns if they like.

6.- When mint day comes around, the project creator / owner will execute the earlyMint function, which will transfer the ETH to their contract and air drop their NFT to everyone who bought through the earlymint campaign. (there is trust involved here, that the project will do what is expected. their contract must implement our earlyMint interface. there is an example of this in contracts/EarlyMintTestERC721A.sol

7.- This allows for projects to gauge the interest of their community by validating it with an actual purchase.

8.- This allows users to receive their NFT first, and without having to be awake / present at mint time.

9.- We will limit the maxOrders, fee (%), and ordersPerWallet

10.- ExternalId is a way to link the campaign to our web2 front end. The client has insisted on keeping this, despite it's gas cost

## ERC721A

https://github.com/chiru-labs/ERC721A

The goal of ERC721A is to provide a fully compliant implementation of IERC721 with significant gas savings for minting multiple NFTs in a single transaction. This project and implementation will be updated regularly and will continue to stay up to date with best practices.

## solidity-campaignable

https://www.npmjs.com/package/solidity-campaignable

# VULNERABILITIES

## High

### [H-01] For loop in ensureUniqueCampaignExternalId() could lead to a DoS attack

Affected Functions:

- `modifier ensureUniqueCampaignExternalId()`

Description:

- To check if a particular signature has already been used, the ensureUniqueCampaignExternalId() modifier iterates through the entire campaignList[] mapping. With each new campaign, the iteration gets bigger and bigger until the transaction runs out of gas.
- Given that `ensureUniqueCampaignExternalId()` modifier is used on `createCampaign()`, if a state is reached in which the aforementioned loop exceeds the gas limit, `createCampaign()` will always revert, thus rendering `OneMinter`'s Campaign creation functionality unusable.

Mitigation:

- The best approach to this situation would be to rework the strategy for verifying whether \_externalId has already been used, by storing them on a Mapping instead of having to check every Campaign on the array. This would result in a constant time operation, thus avoiding the need for a loop.

An example of this new modifier could be:

```solidity
// Create a mapping to bind externalId hash to a Campaign ID
// AND make sure the first Campaign ID is 1, not 0
mapping(bytes32 => uint256) campaignsByExternalId;
...
modifier ensureUniqueCampaignExternalId(string memory _externalId) {
    // Check whether the hash of the externalId has already been used
    require(campaignsByExternalId[keccak256(abi.encodePacked(_externalId))] == 0, "EarlyMint: Campaign with this externalId already exists");
    _;
}
```

### [H-02] For loop in executeMintForCampaign() could lead to a DoS attack

- The function ` executeMintForCampaign()` loops through all the Campaign participants as per `paidOrdersAddresses` array. This means that with enough participants, the function can run out of gas and revert. This situation would perpetually lock the `executeMintForCampaign()` for this Campaign, and given that there is no logic to remove users from the `paidOrdersAddresses` paidOrdersAddresses array, the Campaign would be stuck in this state forever.
- It would seem that this scenario would be prevented by the Campaign's `maxOrders` and `ordersPerWallet`, but both of these variables are typed `uint256` and are only verified to be greater than 0 on Campaign creation, with no upper bound. This opens the possibility for Campaigns to be created with values that are large enough that could allow enough users to participate in the Campaign and brick the minting process from OOG when trying to loop over all addressesin `paidOrdersAddresses`, similar to [H-01](#h-01-dos---earlymint-can-be-rendered-unable-to-create-new-campaigns-the-more-they-are-created)

Mitigation:

- Consider dividing the minting process into batches and keeping track of the users that were included in the minting process in order to avoid re-minting the same users in following batches.

### [H-03] Not checking \_requestedOrderQuantity != 0 could lead to a DoS attack

- The function `reserveOrder()` does not check `_requestedOrderQuantity()` to be greater than 0. This function can execute with `_requestedOrderQuantity` set to 0, which will add the user to the `paidOrdersAddresses` array, but will not increase the `ordersTotal` variable. This means that an attacker can add themselves to the `paidOrdersAddresses` array without increasing the `ordersTotal` variable, and thus the attacker can add themselves and many other addresses to the `paidOrdersAddresses` array an unlimited amount of times, which will eventually cause the `executeMintForCampaign()` function to run out of gas and revert.

Mitigation:

- Fix the `reserveOrder()` function to revert if `_requestedOrderQuantity` is 0.

## [H-03] Malicious Campaign Creator can steal funds instead of minting NFTs passively or by frontrunning

Affected Functions:

- `executeMintForCampaign()`
- `updatePaymentAddress()`

Description:

## Medium

## Low

## QA

### [QA-01] Floating Pragma Solidity Version could lead to a potential vulnerability

Affected Functions:

- `pragma solidity >=0.8.17 <0.9.0;`

Description:

- Contracts should be deployed using the same compiler version/flags with which they have been tested. Locking the pragma ensures that contracts do not accidentally get deployed using an different compiler version with uncontrolled bugs.

### [QA-02] Consider declaring functions as `external`

Affected Functions:

- `EarlyMint` Functions
  - `updateAuthorizerAddress()`
  - `requestRefund()`
  - `createCampaign()`
  - `deleteCampaign()`
  - `setUnMinted()`
  - `updatePaymentAddress()`
  - `executeMintForCampaigns()`
  - `reserveOrder()`
  - `updateWalletAddress()`
  - `withdraw()`
  - `withdrawAmount()`
- `EarlyMint` View Functions
  - `getPriceToReserveOrders()`
  - `getCampaignByExternalId()`
  - `getPaymentAddress()`
  - `getPaidOrdersByCampaignId()`
  - `getMyCampaignIDs()`
  - `getCampaignsManagedByAddress()`

Description:

- The aforementioned functions are defined as `public` but are not used internally. Consider defining them as `external` instead to save gas.

### [QA-03] Private variables cost less gass than public

Affected Variables:

- `campaignCounter`
- `authorizerAddress`
- `campaignList`
- `paidOrders`
- `paidOrdersAddresses`

Description:

- Consider defining those variables as private and creating getter functions for those that it's necessary.

### [QA-04] Use of the Open Zeppelin Access Control Library to create profiles

Affected Variables:

- `authorizerAddress`

Description:

- Consider using the OZ Access Library to create user profiles with full control rather than defining them individually

### [QA-05] Use ++variable rather than variable++ to save gass

Affected functions:

`ensureUniqueCampaignExternalId`
`createCampaign`
`executeMintForCampaign`
`executeMintForCampaigns`
`addPaidOrdersAddress`
`getMyCampaignIDs`
`getCampaignsManagedByAddress`

Description:

- ++variable Costs Less Gas Than variable++, Especially When It's Used In For-loops (--i/i-- Too). variable++ contains two extra instructions compared to ++variable. These two instructions are DUP (3 gas) and POP (2 gas).

### [QA-06] Repeated access to loop break condition

Affected functions:

`executeMintForCampaign()`
`executeMintForCampaigns()`
`addPaidOrdersAddress()`

Description:

- The functions above all have a loop that checks the length of an array on every iteration.

- In the case of executeMintForCampaign() loop and addPaidOrdersAddress() loop , the length of the array is continuously accessed on every iteration, which involves a read on the paidOrdersAddresses mapping.

- In the case of executeMintForCampaigns() loop, the read is done on the \_campaignIds array, which is better, but it could still be optimized.

Mitigation:

- Store the length of the arrays in memory before the loop and use that variable instead of accessing the array length on every iteration.
- For example, rather than:

```
for (uint256 i = 0; i < paidOrdersAddresses[_campaignId].length; i++) {
    ...continue

```

Do this:

```
uint256 pOALength = paidOrdersAddresses[_campaignId].length;
for (uint256 i = 0; i < pOALength; i++) {
    ...continue

```

### [QA-07] Unnecesary variable initialization

Affected variables:

- [`campaignCounter`](../oneminter/src/EarlyMint.sol#LL18C5-L18C40)
- `i` loop counters ([Example](../oneminter/src/EarlyMint.sol#L30))
- [`counter`](../oneminter/src/EarlyMint.sol#L153)
- [`exists`](../oneminter/src/EarlyMint.sol#L164)

Description

- The variables above are all explicitly set to `0` when that is already their default value. This is a trivial issue, but I figured I'd mention it for minor optimization purposes.

Mitigation

- Remove the unnecessary variable initialization.

### [QA-08] Using `memory` for read-only parameters

Affected Functions

- `EarlyMint`
  - [`createCampaign()`]
  - [`getCampaignByExternalId()`]
  - [`executeMintForCampaigns()`]
  - [`reserveOrder()`]

Description

- The functions above all have parameters that are declared as `memory` but are only read from nor are they used as parameters for other functions. `calldata` is way cheaper to access than `memory`.

Mitigation

- Declare the complex parameters as `calldata` instead of `memory` to avoid loading them into memory automatically.

### [QA-09] Use a Pointer instead of accessing mapping multiple times and cache values when possible

Affected Functions

`executeMintForCampaign()`

Description:

Inside the function, we have the for loop:

```
for (uint256 i; i < pOALength; i++) {
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
```

Declare a `storage` pointer to the `Campaign` struct from `campaignList` instead of accessing it multiple times repeatedly.

Mitigation

Declare

```
  Campaign storage campaign = campaignList[_campaignId];
```

Replace all uses of `campaignList[_campaignId].x` with `campaign.x`, for example, in
`campaignList[_campaignId].price`
`campaignList[_campaignId].fee `

### [QA-10] `reserveOrder()` accepts overpayment

Affected Functions

- `EarlyMint`
- `reserveOrder()`

Description

- The function checks that the ETH sent is greater than the expected value instead of it being equal, which allows for users to overpay and still have the transaction go through. This ETH is not lost as it can be recovered by the owner through the use of `withdraw()` and `withdrawAmount()`, but otherwise this additional ETH balance in the contract is not accounted for by any state variables.

Mitigation

Change the `>=` to `==` in the `require()` statement.
