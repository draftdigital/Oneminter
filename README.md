# One Minter (SLOC: 391 - Audit Cost: $2360)

One Minter is the opportunity for Projects to gather funds in advance. Our software will be a step forward in the investment options

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
