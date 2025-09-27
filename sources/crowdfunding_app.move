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

    // 👇 añadido: evento para que el frontend pueda listar campañas
    public struct CampaignCreated has copy, drop {
        campaign_id: address,
        owner: address,
        goal: u64,
        deadline: u64,
    }



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
        //treasury: Coin<SUI>,

    }

    public struct Contribution has key,store{
        id: UID,              // Identificador único del objeto en Sui
        campaign_id: address, // Dirección del objeto Campaign al que se contribuye
        contributor: address, // Dirección del usuario que contribuye
        amount: u64,          // Monto de la contribución
        refunded: bool,       // Indica si la contribución fue reembolsada


    }


    /*
    Crear campaña.
    Contribuir a una campaña.
    Reclamar fondos si la campaña es exitosa.
    Devolver fondos si la campaña falla.



    */
    

    //Creates a campaign
    #[lint_allow(self_transfer)]
    public entry fun create_campaign(goal: u64, duration_ms: u64, name: string::String,description: string::String ,clock: &Clock, ctx: &mut TxContext) {// ,deadline: u64,
        //let id = object::new(ctx);
        //let owner = tx_context::sender(ctx);
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

        // 👇 emitimos evento para el frontend
        event::emit(CampaignCreated {
            campaign_id: object::uid_to_address(&cam.id),
            owner: cam.owner,
            goal,
            deadline,
        });


        
        //transfer::transfer(cam, ctx.sender()); //IMPORTANTE VER QUE HACER AQUI. SI DEJAR COMO ESTÁ O BIEN MANDAR AL ADMIN U OTRA COSA
        transfer::share_object(cam);

    }



    /*
    para mejorar debeía poder enviar los fondos a una cartera temporal o tesoro en el cual cuando se alcanze el límite el propietario lo pueda reclamar
     !Buscar como hacer!


     Ver si usar el modelo flexible o todo o nada

     Ver si cobramos comisiones
    */

    public entry fun contribute(campaign: &mut Campaign, coin: coin::Coin<SUI>, ctx: &mut TxContext) {
        let amount = coin::value(&coin);
        campaign.total_raised = campaign.total_raised + amount;
        coin::join(&mut campaign.treasury, coin);

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



