/*
/// Module: crowdfunding_app
module crowdfunding_app::crowdfunding_app;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions



module crowdfunding_app::crowdfunding_app{
    use std::string;
    use sui::object::{Self, UID};
    //use sui::coin::Coin;
    //use sui::coin::{Coin, zero};
    //use sui::coin::{Coin, zero, value, merge};
    use sui::coin;
    use sui::sui::SUI;
    use sui::event;
    use sui::clock::Clock;


    /// Event emitted when a new campaign is created.
    /// 
    /// This event allows the frontend or indexers to track and list all campaigns.
    /// 
    /// Fields:
    /// - `campaign_id`: The unique address of the newly created campaign.
    /// - `owner`: The address of the campaign creator/owner.
    /// - `goal`: The funding goal for the campaign (in the smallest unit, e.g., SUI).
    /// - `deadline`: The campaign's deadline as a Unix timestamp.
    public struct CampaignCreated has copy, drop {
        campaign_id: address,
        owner: address,
        goal: u64,
        deadline: u64,
    }


    /// Represents a crowdfunding campaign.
    /// Stores campaign details such as the owner, admin, funding goal, deadline, total amount raised, 
    /// status (active or not), treasury holding the raised SUI coins, list of contributions, 
    /// and metadata like name and description.

    public struct Campaign has key, store{
        id: UID,
        owner: address,
        admin: address,
        goal: u64,
        deadline: u64,
        total_raised: u64,
        is_active: bool,
        treasury: coin::Coin<SUI>,
        contributions: vector<Contribution>,
        name: string::String,        
        description: string::String,

    }

    /// Represents a single contribution to a crowdfunding campaign.
    /// Stores the unique ID, the campaign's address, the contributor's address,
    /// the contributed amount, and whether the contribution has been refunded.

    public struct Contribution has key,store{
        id: UID,              // Identificador único del objeto en Sui
        campaign_id: address, // Dirección del objeto Campaign al que se contribuye
        contributor: address, // Dirección del usuario que contribuye
        amount: u64,          // Monto de la contribución
        refunded: bool,       // Indica si la contribución fue reembolsada


    }


    
    

    /// Creates a new crowdfunding campaign.
    /// 
    /// - Initializes a new `Campaign` object with the specified funding goal, duration, name, and description.
    /// - Sets the campaign owner to the transaction sender and the admin to a fixed address.
    /// - Calculates the campaign deadline based on the current timestamp and the provided duration.
    /// - Initializes the campaign treasury and contributions list.
    /// - Emits a `CampaignCreated` event for frontend tracking.
    /// - Shares the campaign object so it can be accessed on-chain.
    /// 
    /// Parameters:
    /// - `goal`: The funding goal for the campaign.
    /// - `duration_ms`: Duration of the campaign in milliseconds.
    /// - `name`: Name of the campaign.
    /// - `description`: Description of the campaign.
    /// - `clock`: Reference to the on-chain clock for timestamping.
    /// - `ctx`: Mutable transaction context.
    /// 
    #[lint_allow(self_transfer)]
    public entry fun create_campaign(goal: u64, duration_ms: u64, name: string::String,description: string::String ,clock: &Clock, ctx: &mut TxContext) {
        let now = clock.timestamp_ms();
        let deadline = now + duration_ms;

        let cam = Campaign {
            id: object::new(ctx) ,
            owner: tx_context::sender(ctx),
            admin: @0x9f44045feeafbfb27342e9aa325bade7a558366993ab736fd01a02215a0379e6 ,
            goal,
            deadline,
            total_raised: 0,
            is_active: true,
            treasury: coin::zero<SUI>(ctx),
            contributions: vector::empty<Contribution>(),
            name,
            description,
        };

        //  emitimos evento para el frontend
        event::emit(CampaignCreated {
            campaign_id: object::uid_to_address(&cam.id),
            owner: cam.owner,
            goal,
            deadline,
        });


        
        //transfer::transfer(cam, ctx.sender()); //IMPORTANTE VER QUE HACER AQUI. SI DEJAR COMO ESTÁ O BIEN MANDAR AL ADMIN U OTRA COSA
        transfer::share_object(cam);

    }

    /// Allows a user to contribute SUI coins to a crowdfunding campaign.
    /// 
    /// - Adds the contributed amount to the campaign's total raised.
    /// - Joins the contributed coin into the campaign's treasury.
    /// - Creates a new `Contribution` object recording the contributor, amount, and refund status.
    /// - Stores the `Contribution` in the campaign's contributions vector.
    /// 
    /// Parameters:
    /// - `campaign`: Mutable reference to the `Campaign` being contributed to.
    /// - `coin`: The SUI coin being contributed.
    /// - `ctx`: Mutable transaction context.

    public entry fun contribute(campaign: &mut Campaign, coin: coin::Coin<SUI>,  clock: &Clock, ctx: &mut TxContext) {//clock: &Clock,
        
        let now = clock.timestamp_ms();
        if (now > campaign.deadline || !campaign.is_active) {
            // Llama a refund para reembolsar a todos los contribuyentes
            refund(campaign, clock, ctx);
            // Devuelve la moneda al usuario que intentó contribuir fuera de plazo
            transfer::public_transfer(coin, tx_context::sender(ctx));
            return;
        };
        
        
        
        let amount = coin::value(&coin);
        campaign.total_raised = campaign.total_raised + amount;
        coin::join(&mut campaign.treasury, coin);

        /*let now = clock.timestamp_ms();
        if (now > campaign.deadline || !campaign.is_active) {
            // Llama a refund para reembolsar a todos los contribuyentes
            refund(campaign, clock, ctx);
            // Devuelve la moneda al usuario que intentó contribuir fuera de plazo
            transfer::public_transfer(coin, tx_context::sender(ctx));
            return;
        };*/

        // Crear el objeto Contribution
        let contribution = Contribution {
            id: object::new(ctx),
            campaign_id: campaign.owner, // O usa la dirección del objeto Campaign si la tienes
            contributor: tx_context::sender(ctx),
            amount,
            refunded: false,
        };

        // Transferir el objeto Contribution al contribuyente
        //transfer::transfer(contribution, tx_context::sender(ctx));
        vector::push_back(&mut campaign.contributions, contribution);

    }

    /// Refunds all contributors of a campaign if the funding goal was not reached.
    /// 
    /// - Only the campaign admin or anyone after the campaign deadline can execute refunds.
    /// - Ensures refunds are only processed if the campaign did NOT reach its funding goal.
    /// - Iterates through all contributions:
    ///     - Marks each as refunded.
    ///     - Splits the corresponding amount from the campaign treasury.
    ///     - Transfers the refund back to the original contributor.
    /// - Deactivates the campaign after processing refunds.
    /// 
    /// Parameters:
    /// - `campaign`: Mutable reference to the `Campaign` to refund.
    /// - `clock`: Reference to the on-chain clock for deadline checks.
    /// - `ctx`: Mutable transaction context.

    public entry fun refund(campaign: &mut Campaign, clock: &Clock, ctx: &mut TxContext) { //PRIMERA VERSIÓN ¡¡¡¡PONER QUE SOLO ADMIN O PERSONAS PERMITIDAS (AdminCap)!!!!!

        // Solo el admin puede ejecutar el reembolso
        assert!(tx_context::sender(ctx) == campaign.admin || clock.timestamp_ms() > campaign.deadline, 1);
        // Solo permite reembolsos si la campaña NO alcanzó el goal
        assert!(campaign.total_raised < campaign.goal, 0);

        let mut i = 0;
        while (i < vector::length(&campaign.contributions)) {
            let mut contribution = vector::borrow_mut(&mut campaign.contributions, i); //da una referencia mutable
            if (!contribution.refunded) {
                // Marca como reembolsada
                contribution.refunded = true;

                // Separa la cantidad correspondiente del tesoro
                let refund_coin = coin::split(&mut campaign.treasury, contribution.amount, ctx);

                // Transfiere el reembolso al contribuyente
                //transfer::transfer(refund_coin, contribution.contributor);
                transfer::public_transfer(refund_coin, contribution.contributor);

            };
            i = i + 1;
        };
        //desactiva la campaña
        campaign.is_active = false;
    }




    /// Allows the campaign owner to claim the raised funds if the campaign was successful.
    /// 
    /// - Only the campaign owner can call this function.
    /// - Ensures the campaign reached its funding goal and is still active.
    /// - Calculates a 2% fee for the admin and 98% for the owner.
    /// - Splits the treasury accordingly:
    ///     - 98% is sent to the campaign owner.
    ///     - 2% is sent to the admin address.
    /// - Deactivates the campaign after funds are claimed.
    /// 
    /// Parameters:
    /// - `campaign`: Mutable reference to the `Campaign` to claim funds from.
    /// - `ctx`: Mutable transaction context.
    
    public entry fun claim_funds(campaign: &mut Campaign, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == campaign.owner, 1);
        assert!(campaign.total_raised >= campaign.goal, 2);
        assert!(campaign.is_active, 3);

        let total = coin::value(&campaign.treasury);
        let two_percent = total * 2 / 100;
        let ninety_eight_percent = total - two_percent;

        let funds_owner = coin::split(&mut campaign.treasury, ninety_eight_percent, ctx);
        let funds_admin = coin::split(&mut campaign.treasury, two_percent, ctx);

        transfer::public_transfer(funds_owner, campaign.owner);
        transfer::public_transfer(funds_admin, @0x9f44045feeafbfb27342e9aa325bade7a558366993ab736fd01a02215a0379e6);

        campaign.is_active = false;
    }








}


/*public struct AdminCap has key {
        id: UID
    }

    fun init(ctx: &mut TxContext) {//entry
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, ctx.sender())
    }

    public fun add_admin(_cap: &AdminCap, new_admin: address, ctx: &mut TxContext) {
        transfer::transfer(
            AdminCap {
                id: object::new(ctx)
            },
            new_admin,
        )
    }*/



