# crowdfunding_app

Frontend in another github:
https://github.com/SoteroR/hackaton-frontend-sui#

Examples of blockchain objects:

Campaign: 0x788cede702044ee43070e8af8b386410fe35aa2c58e003a47c01638d070a8b0f

NFT: 0xe71ed1382014d333e8d83958bcd86ed374141bc70f2fc1a62d5c2cb79e6841bf


Crowdfunding App on Sui

A decentralized crowdfunding platform built on the Sui blockchain using Move. Users can create campaigns, contribute SUI coins, and receive NFT rewards for their contributions.

Features

Create Campaigns: Users can create crowdfunding campaigns with a goal, deadline, description, and an associated NFT.

Contribute Funds: Anyone can contribute SUI to active campaigns.

Refunds: Contributors are automatically refunded if the campaign fails to reach its goal.

Claim Funds: Campaign owners can claim the raised funds if the campaign succeeds.

NFT Rewards: Contributors receive a custom NFT as a thank-you for their donation.

Event Tracking: All campaign creation events are emitted for frontend or indexer tracking.

Project Structure

The main module is located at:

crowdfunding_app::crowdfunding_app

Main Structs

Campaign

Stores campaign details such as owner, goal, deadline, total raised, treasury, and contributions.

Contribution

Records individual contributions, including contributor address, amount, and refund status.

CampaignCreated

Event emitted when a new campaign is created.

DonationNFT

NFT rewarded to contributors.

Usage
1. Create a Campaign
create_campaign(
    goal: u64,
    duration_ms: u64,
    name: string::String,
    description: string::String,
    nft_url_bytes: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext
)


goal: Funding goal in SUI.

duration_ms: Duration of the campaign in milliseconds.

name: Campaign name.

description: Campaign description.

nft_url_bytes: Optional URL for the NFT image (default used if empty).

2. Contribute to a Campaign
contribute(campaign: &mut Campaign, coin: coin::Coin<SUI>, clock: &Clock, ctx: &mut TxContext)


Contribute SUI to an active campaign.

Automatically receives an NFT as a reward.

Refunds are issued if the campaign fails.

3. Claim Funds
claim_funds(campaign: &mut Campaign, ctx: &mut TxContext)


Allows the campaign owner to claim funds if the goal is reached.

2% fee is sent to the admin, 98% to the owner.

4. Refund Campaign
refund(campaign: &mut Campaign, clock: &Clock, ctx: &mut TxContext)


Refunds contributors if the campaign fails to reach its goal.

Only executable by the admin or after the deadline.

Frontend Repository

The frontend for interacting with this contract is hosted here:

Frontend GitHub Repository

Examples of Objects on Sui

Campaign: 0x788cede702044ee43070e8af8b386410fe35aa2c58e003a47c01638d070a8b0f

NFT: 0xe71ed1382014d333e8d83958bcd86ed374141bc70f2fc1a62d5c2cb79e6841bf

Requirements

Sui CLI

Rust 1.72+ (for Move compiler)

Node.js & npm (for frontend)

Contributing

Fork the repository.

Create a new branch: git checkout -b feature/my-feature

Make your changes.

Commit: git commit -m 'Add some feature'

Push: git push origin feature/my-feature

Open a Pull Request.
