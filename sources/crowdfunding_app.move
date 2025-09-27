/*
/// Module: crowdfunding_app
module crowdfunding_app::crowdfunding_app;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions




/*module crowdfunding_app::crowdfunding_app {
    use sui::object::{Self, UID};
    use sui::coin::{Coin, self};
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    public struct Campaign has key {
        id: UID,
        owner: address,
        goal: u64,
        deadline: u64,
        total_raised: u64,
        is_active: bool,
        treasury: Coin<SUI>,
    }

    public struct Contribution has key {
        id: UID,
        campaign_id: UID,
        contributor: address,
        amount: u64,
        refunded: bool,
    }

    /// Create a new campaign
    public entry fun create_campaign(goal: u64, deadline: u64, ctx: &mut TxContext): Campaign {
        let id = object::new(ctx);
        let owner = tx_context::sender(ctx);
        let treasury = coin::zero<SUI>();
        Campaign {
            id,
            owner,
            goal,
            deadline,
            total_raised: 0,
            is_active: true,
            treasury,
        }
    }

    /// Contribute to a campaign
    public entry fun contribute(campaign: &mut Campaign, coin: Coin<SUI>, ctx: &mut TxContext) {
        let amount = coin::value(&coin);
        campaign.total_raised = campaign.total_raised + amount;
        coin::merge(&mut campaign.treasury, coin);
        // Optionally, create a Contribution object here
    }
}*/


module crowdfunding_app::crowdfunding_app{
    use std::string;
    use sui::object::{Self, UID};
    //use sui::coin::Coin;
    use sui::coin::{Coin, zero};
    use sui::sui::SUI;

    public struct Campaign has key, store{
        id: UID,
        owner: address,
        //admin: address,
        goal: u64,
        deadline: u64,
        total_raised: u64,
        is_active: bool,
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

     /// Función para crear una nueva campaña
        /// Create a new campaign
    
    #[lint_allow(self_transfer)]
    /*public fun create_campaign(goal: u64, deadline: u64, ctx: &mut TxContext): Campaign {//entry 
        let id = object::new(ctx);
        let owner = tx_context::sender(ctx);
        //let treasury = sui::coin::zero;//zero<SUI>(); //coin::zero<SUI>();
        let cam = Campaign {
            id,
            owner,
            goal,
            deadline,
            total_raised: 0,
            is_active: true,
            //treasury,
        };
        //transfer::public_transfer(cam, owner);
        //return cam
        transfer::transfer(cam, tx_context::sender(ctx));
    }*/
    public entry fun create_campaign(goal: u64, deadline: u64, ctx: &mut TxContext) {
    //let id = object::new(ctx);
    //let owner = tx_context::sender(ctx);
    let cam = Campaign {
        id: object::new(ctx) ,
        owner: tx_context::sender(ctx),
        goal,
        deadline,
        total_raised: 0,
        is_active: true,
    };
    transfer::transfer(cam, ctx.sender());
}



    /*
    para mejorar debeía poder enviar los fondos a una cartera temporal o tesoro en el cual cuando se alcanze el límite el propietario lo pueda reclamar
     !Buscar como hacer!


     Ver si usar el modelo flexible o todo o nada

     Ver si cobramos comisiones
    */

    /*public entry fun contribute( campaign: &mut Campaign, coin: Coin<SUI>, ctx: &mut TxContext) {
        let amount = coin::value(&coin);
        // Sumar la contribución al total recaudado
        campaign.total_raised = campaign.total_raised + amount;
        //transferir
        coin::merge(&mut campaign.treasury, coin);
    }*/


}
