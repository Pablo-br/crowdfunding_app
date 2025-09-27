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
    public entry fun create_campaign(goal: u64, deadline: u64, ctx: &mut TxContext) {
    //let id = object::new(ctx);
    //let owner = tx_context::sender(ctx);
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
    };
    transfer::transfer(cam, ctx.sender()); //IMPORTANTE VER QUE HACER AQUI. SI DEJAR COMO ESTÁ O BIEN MANDAR AL ADMIN O OTRA COSA
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



}
