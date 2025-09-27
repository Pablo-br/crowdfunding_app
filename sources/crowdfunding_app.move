/*
/// Module: crowdfunding_app
module crowdfunding_app::crowdfunding_app;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module crowdfunding_app::crowdfunding_app{
    use std::string;
    use sui::object::{Self, UID};
    use sui::coin::Coin;
    use sui::sui::SUI;

    public struct Campaign has key{
        id: UID,
        owner: address,
        goal: u64,
        deadline: u64,
        total_raised: u64,
        is_active: bool,

    }

    public struct Contribution has key{
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
    public entry fun create_campaign(goal: u64, deadline: u64, ctx: &mut TxContext): 
        Campaign {
            let id = object::new(ctx);
            let owner = tx_context::sender(ctx);
            Campaign {
                id,
                owner,
                goal,
                deadline,
                total_raised: 0,
                is_active: true,
            };

        transfer::transfer(campaign, owner);
    }

    /*
    para mejorar debeía poder enviar los fondos a una cartera temporal o tesoro en el cual cuando se alcanze el límite el propietario lo pueda reclamar
     !Buscar como hacer!


     Ver si usar el modelo flexible o todo o nada

     Ver si cobramos comisiones
    */

    public entry fun contribute( campaign: &mut Campaign, coin: Coin<SUI>, ctx: &mut TxContext) {
        let amount = coin::value(&coin);
        // Sumar la contribución al total recaudado
        campaign.total_raised = campaign.total_raised + amount;
        //transferir
        coin::merge(&mut campaign.treasury, coin);
    }


}

