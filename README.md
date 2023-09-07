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
    - [\[H-04\] Malicious Campaign Creator can steal funds instead of minting NFTs passively or by frontrunning](#h-04-malicious-campaign-creator-can-steal-funds-instead-of-minting-nfts-passively-or-by-frontrunning)
    - [\[H-05\] Loss of funds due to changing the balance of an existing address](#h-05-loss-of-funds-due-to-changing-the-balance-of-an-existing-address)
  - [Medium](#medium)
    - [\[M-01\] Owner can delete Campaigns without restrictions](#m-01-owner-can-delete-campaigns-without-restrictions)
    - [\[M-02\] Owner can set Campaigns unMinted leading to an uncertain state](#m-02-owner-can-set-campaigns-unminted-leading-to-an-uncertain-state)
    - [\[M-03\] Withdraw() and WithdrawAmount() can lead to an unestable and unrecovery contract](#m-03-withdraw-and-withdrawamount-can-lead-to-an-unestable-and-unrecovery-contract)
  - [Low](#low)
    - [\[L-01\] Unreliable `msg.sender` on View function and redundant functionality](#l-01-unreliable-msgsender-on-view-function-and-redundant-functionality)
    - [\[L-02\] Signature Replayability](#l-02-signature-replayability)
    - [\[L-03\] Using `transfer()` for transferring ETH](#l-03-using-transfer-for-transferring-eth)
    - [\[L-04\] Not following Checks-Effects-Interactions pattern](#l-04-not-following-checks-effects-interactions-pattern)
    - [\[L-05\] Unchecked existence of Campaign using `_campaignId`](#l-05-unchecked-existence-of-campaign-using-_campaignid)
    - [\[L-06\] Loops on View functions can run out of gas when called from within a transaction](#l-06-loops-on-view-functions-can-run-out-of-gas-when-called-from-within-a-transaction)
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

### [H-04] Malicious Campaign Creator can steal funds instead of minting NFTs passively or by frontrunning

Affected Functions:

- `executeMintForCampaign()`
- `updatePaymentAddress()`

Description:

- Any malicious campaign creator could change the payment address without validation, leading to a potential scam for a potential investor. This address could be a malicious contract that implements `IERC721Contract` interface.
- Additionally, there is also a scenario in which the Campaign creator can front-run the `executeMintForCampaigns()` transaction called by the EarlyMint Owner, and set the `paymentAddress` to a malicious smart contract on the same block before the `executeMintForCampaigns()` one is mined. This would result in the same outcome as the previous scenario but it would be even harder to react to.
- In either case, the users are at risk of the Campaign creator taking their funds without them receiving anything in exchange.

Mitigation:

- Easiest solution would be to make use of the already existing centralized aspects of `EarlyMint` to check and authorize the `paymentAddress` before a Campaign creator can set it.

- For `createCampaign()`, add the `paymentAddress` to the signature provided by the Authorizer. This will ensure that the user cannot input an arbitrary value for this field, or that at least this value (should) have been checked by the EarlyMint team before authorizing it.

- For `updatePaymentAddress()`, add a new signature requirement with a similar process of signature validation as the one used in `createCampaign()`.

### [H-05] Loss of funds due to changing the balance of an existing address

Affected fuctions:

- `requestRefund()`
- `executeMintForCampaign()`
- `updateWalletAddress()`

- `updateWalletAddress()` does not check if the address is already in array `paidOrdersAddresses`. In this way, any malicious actor could add an address that already has a balance, but, in this case, setting the balance to 0.

Mitigation:

- three different solutions to this issue:

1. Update `updateWalletAddress()` to check whether the `_newAddress` already has an Order balance, and revert if it does.

2. Update `updateWalletAddress()` to check whether the `_newAddress` already has an Order balance, and if it does, **transfer** the caller's Orders to the `_newAddress`'s Order balance instead of **overwriting** them. This would also require checking that the `_newAddress`'s Order balance does not exceed the max orders per wallet limit.

3. Make the `updateWalletAddress()` usecase a two-step process, where the user first calls `updateWalletAddress()` to signal their intent to update their wallet address to `_newAddress`, and then only allow `_newAddress` to call a new function `acceptWalletAddressUpdate()` to accept the update.

## Medium

### [M-01] Owner can delete Campaigns without restrictions

- The fact that the owner has the power to delete campaigns without any restriction or control led the project into a 2 potential problems:

1. Database inconsistency: Put the contract in an undesired state, also, it can harm users by deleting the Campaign parameters while users have reserved Orders.

2. Malicious users can benefit: clearing the Campaign includes clearing its `externalId`, which would allow anyone to create a new Campaign with the same `externalId`. One user could turn malicious and wait until other users participate in this new Campaign. As soon as `ordersTotal` and `campaignBalance` are big enough, she can withdraw the funds with her still existent 5 Order record by calling `requestRefund()` once the new Campaign data is in place, thus getting a refund for 5 Orders that might be valued at a different price.

### [M-02] Owner can set Campaigns unMinted leading to an uncertain state

ffected Functions

- `setUnMinted()`
- `executeMintForCampaign()`

Description:

The `executeMintForCampaign()` function only sets the state of a Campaign to `minted` when executed. All other variables and structures are left untouched, which includes a user's Order balance as per the `paidOrders` mapping. As a matter of fact, the only thing stopping `executeMintForCampaign()` from being called multiple times for the same Campaign is whether it has been minted or not.

If a user has reserved Orders for a Campaign and the Campaign is minted, they will still have a non-zero balance on their `paidOrders` and the Campaign parameters are also still set. This opens up a vector in which they are able to `requestRefund()` as soon as `setUnMinted()` is called. In a scenario where `EarlyMint` has enough ETH balance (ETH leftover from fees; other active Campaigns have not been minted yet; etc), the user can successfully call `requestRefund()` and withdraw funds corresponding to their Orders balance, eventhough they had already participated in the Campaign minting.

Mitigation:

Make use of the known participating user address inside the loop to clear their `paidOrders` balance. This will ensure that the user cannot withdraw their funds if they have already participated in the minting of the Campaign.

### [M-03] Withdraw() and WithdrawAmount() can lead to an unestable and unrecovery contract

Even assuming the owner's good faith, the fact that it is possible to withdraw the funds without any other action in the database could lead to unexpected consequences.

The only reason to accept these functions is to destroy the contract and send the balance to the owner. All ongoing campaigns will be inconsistent.

If the intention was to withdraw fees, a safer approach would be to keep track of the fees left in the contract after a successful campaign mint, and create a withdrawFees function that allows the owner to withdraw only that amount. This would ensure that the Owner is not able to withdraw funds that do not belong to them, thus bricking the entire protocol, as well as giving users more confidence in the protocol.

## Low

### [L-01] Unreliable `msg.sender` on View function and redundant functionality

Affected Functions

- `EarlyMint`
  - `getMyCampaignIDs()`

Description

The function [`getMyCampaignIDs()`](https://github.com/johnny-sch-course/EarlyMintAudit/blob/4e12c85f49fda20eb2227649b110bb54eba8f79e/contracts/EarlyMint.sol#L139) is declared as `view` and inside it, the `msg.sender` is used to retrieve the campaigns that the caller has created. However, when a view function is executed off-chain, `msg.sender` is not reliable as this value can be set arbitrarily by the caller as signatures are not verified on these type of calls.

Additionally, `getMyCampaignIDs()` is redundant, as this same functionality can be achieved by using the [`getCampaignsManagedByAddress()`](https://github.com/johnny-sch-course/EarlyMintAudit/blob/4e12c85f49fda20eb2227649b110bb54eba8f79e/contracts/EarlyMint.sol#L151) function. Both off-chain and on-chain calls can pass their address as a parameter to retrieve the campaigns that they have created, resulting in a more reliable code; and freeing up deployment cost for `EarlyMint` by getting rid of the `getMyCampaignIDs()` function.

Mitigation

Consider removing the `getMyCampaignIDs()` function and using `getCampaignsManagedByAddress()` instead.

### [L-02] Signature Replayability

Affected Modifiers

- `Campaignable`
  - `isValidCreate()`
  - `isValidReserve()`

Description

Current signature use in `isValidCreate()` involves the following [parameters](https://github.com/johnny-sch-course/EarlyMintAudit/blob/4e12c85f49fda20eb2227649b110bb54eba8f79e/contracts/Campaignable.sol#LL42C3-L44C4):

- `contractAddress`
- `msg.sender`
- `campaignId`
- `"create"`
- `fee`

and for `isValidReserve()`, the [parameters](https://github.com/johnny-sch-course/EarlyMintAudit/blob/4e12c85f49fda20eb2227649b110bb54eba8f79e/contracts/Campaignable.sol#L53-L55):

- `contractAddress`
- `msg.sender`
- `campaignId`
- `"reserve"`

However, the signature validation modifiers work in a way that allows replayability. Once a valid signature is created, it can be sent to these modifiers and, as long as the caller-defined parameters are the same as the signed ones, the signature will be successfully verified and allow the caller to continue the function execution. The only safeguarding aspect of current signatures is that the `msg.sender` is included in it, which means that it can only be replayed by the same caller it was originally signed for.

The reason I report this as a Low severity issue is that currently this is not a vulnerability, as the only functions that use these modifiers are `createCampaign()` and `reserveOrder()`:

- `createCampaign()` calls `ensureUniqueCampaignExternalId()` which verifies that the inputted `externalId` is not in use. The signature itself is valid, but the function will revert if the `externalId` already exists thus preventing any kind of malicious overriding.
- `reserveOrder()` does not have any additional validation, but replaying the signature will not result in malicious results as the signature binds the caller to a specific Campaign, which means that the caller cannot reserve an order for a different Campaign ID than the one it was signed for and `requestOrderQuantity` validations still apply.

This being said, if these modifiers were to be used on other functions at some point in time, it is worth noting that they would be vulnerable to replayability.

Mitigation

If this is the behaviour expected by the protocol, to allow users to only need one signature to perform multiple actions, then no mitigation is needed.

However, if the protocol expects to only allow one action per signature, then the signature should be modified to include a `nonce` per caller, which is incremented every time the signature is used, and thus preventing replayability.

### [L-03] Using `transfer()` for transferring ETH

Affected Functions

- `EarlyMint`
  - `requestRefund()`

Description

The use of `transfer()` for [sending ETH to the caller](https://github.com/johnny-sch-course/EarlyMintAudit/blob/4e12c85f49fda20eb2227649b110bb54eba8f79e/contracts/EarlyMint.sol#L46) in `requestRefund()` should be avoided to prevent potential DoS.

`transfer()` only forwards 2300 gas to the recipient, so if the caller is a contract that implements a fallback function that consumes more than 2300 gas, the transfer will fail. This will result in the `requestRefund()` function reverting and the caller will not be able to withdraw their funds. (Keep in mind these smart contract callers could be non-malicious contracts like Multisig wallets).

Mitigation

Use `call()` instead of `transfer()` like so:

```solidity
(bool success, ) = payable(msg.sender).call{value: refundAmount}("");
require(success, "Transfer failed.");
```

### [L-04] Not following Checks-Effects-Interactions pattern

¡Affected Functions

- `EarlyMint`
  - `requestRefund()`

Description

Not following the CEI pattern can lead to attack vectors that make use of stale / outdated contract state, for example, through Reentrancy.

When [transferring ETH to the caller](https://github.com/johnny-sch-course/EarlyMintAudit/blob/4e12c85f49fda20eb2227649b110bb54eba8f79e/contracts/EarlyMint.sol#L46) in `requestRefund()` the values of `ordersTotal`, `campaignBalance` and `paidOrders` have not yet been updated despite the transfer of ETH being done. This very call to the caller (`payable(msg.sender).transfer(refundAmount)`) could be used by a malicious contract to re-enter the `EntryMint` contract and call functions without reentrancy guards that would use the stale values of the aforementioned variables to lead the contract into an inconsistent state.

At the time of writing, this particular vector seems to not be a problem given the current unprotected functions, but it should be taken into account for future changes.

### [L-05] Unchecked existence of Campaign using `_campaignId`

Affected Functions

- `EarlyMint`
  - `getPriceToReserveOrders()`

Description

The function makes no existence checks after accessing `campaignList[_campaignId]`. When a campaign is non-existent, `campaignList[_campaignId].price` value will be `0`, and thus the function will always return `0` for Campaigns that do not exist.

Given that this is a view function, and that this is not being used internally by the `EarlyMint` contract, there is no logic being put at risk. However, for external callers that make use of this function, a non-existent Campaign will be indistinguishable from a Campaign that has a price of `0`.

Mitigation

Assuming that `EarlyMint` allows for Campaigns with a mint price of `0`, (which is possible given the current `createCampaign()` implementation), I would suggest to add another check to verify that the Campaign exists (like checking `creator != address(0)`), and if it does not exist, then revert.

### [L-06] Loops on View functions can run out of gas when called from within a transaction

Affected Functions

- `EarlyMint`
  - `getCampaignByExternalId()`
  - `getMyCampaignIDs()`
  - `getCampaignsManagedByAddress()`

Description

The above functions perform a linear lookup on the `campaignList` mapping by iterating over every Campaign created, as per `campaignCounter` which can grow indefinitely. This means that if the array grows too large, the function will run out of gas when called from within a transaction.

Currently, these functions are not called internally in the `EarlyMint` contract, but external callers might be affected by this.

Mitigation

Similar to [H-01](#h-01-dos---earlymint-can-be-rendered-unable-to-create-new-campaigns-the-more-they-are-created), it would be smarter to use a mapping to keep track of the Campaigns that have a particular `externalId`, even if this means having to manage an additional data structure, the current implementation is not scalable and will fail after enough Campaigns are created.

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
