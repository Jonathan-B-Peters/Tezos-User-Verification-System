#include "../partials/fa2_interface.ligo"
#include "../partials/fa2_extension.ligo"

type ledger is big_map(token_id, address);

type contract_metadata is big_map(token_id, token_metadata)

type storage is
    record [
        ledger  : ledger;
        next_token_id : token_id;
        metadata : contract_metadata
    ]

type return is list (operation) * storage

function fail_on( const condition : bool; const message : string) : unit is if condition then failwith (message) else unit

function transfer(const params : transfer_params; const store : storage) : return is
block {
    function make_transfer(const acc : return; const parameter : transfer_param) : return is
    block {
        fail_on(parameter.from_ =/= Tezos.sender, "FA2_NOT_OPERATOR");

        fail_on(List.length(parameter.txs) > 1n, "FA2_MULTIPLE_RECIPIENTS");

        const dest : transfer_destination = case List.head_opt(parameter.txs) of
                Some(d) -> d
            | None -> failwith("FA2_NO_RECIPIENT")
        end;

        case Big_map.find_opt(dest.token_id, acc.1.ledger) of
                Some(add) -> fail_on(add =/= parameter.from_, "FA2_NOT_OWNER")
            | None -> failwith("FA2_INVALID_TOKEN_ID")
        end;

        const updated_ledger : ledger = Big_map.update(dest.token_id, Some(dest.to_), acc.1.ledger);
        const updated_storage : storage = acc.1 with record[ ledger = updated_ledger];
    } with ((nil: list(operation)), updated_storage)
} with List.fold(make_transfer, params, ((nil: list(operation)), store))

function balance_of(const parameter : balance_of_params; const store : storage) : return is
block {
    function retreive_balance(const request : balance_of_request) : balance_of_response is
    block {
        var retreived_balance : nat := case Big_map.find_opt(request.token_id, store.ledger) of
              Some(current_owner) -> if (request.owner =/= current_owner) then 0n else 1n
            | None -> 0n
        end
        // const response : balance_of_response = record[request=request; balance=retreived_balance];
    } with record[request=request; balance=retreived_balance];
    const responses : list(balance_of_response) = List.map(retreive_balance, parameter.requests);
    const transfer_operation : operation = Tezos.transaction (responses, 0mutez, parameter.callback);
} with (list[transfer_operation], store)

function mint_id(const params : mint_params; const store : storage) : return is
block {
    function mint_token(const acc : return; const parameter : mint_param) : return is
    block {
        // fail_on(parameter.to_ =/= Tezos.sender, "FA2_NOT_OPERATOR");
        const l : ledger = Big_map.update(acc.1.next_token_id, Some(parameter.to_), acc.1.ledger);
        // const e : token_metadata = nil;
        // const m : contract_metadata = Big_map.update(acc.1.next_token_id, Some(e), acc.1.metadata);
        const id : nat = acc.1.next_token_id + 1n;
    } with ((nil: list(operation)), acc.1 with record[ledger = l; (*metadata = m;*) next_token_id = id])
} with List.fold(mint_token, params, ((nil: list(operation)), store))

function create_entry(const params : create_entry_params; const store : storage) : return is
block {
    function add_entry(const acc : return; const parameter : create_entry_param) : return is
    block {
        // case Big_map.find_opt(parameter.token_id, acc.1.ledger) of
        //       Some (owner) -> fail_on(owner =/= Tezos.sender, "FA2_NOT_OPERATOR")
        //     | None -> failwith("FA2_INVALID_TOKEN_ID")
        // end;
        const tm : token_metadata = case Big_map.find_opt(parameter.token_id, acc.1.metadata) of
              Some (data) -> Map.update((parameter.metadata.title), Some(parameter.metadata), data)//cons(parameter.metadata, data)
            | None -> map[parameter.metadata.title -> parameter.metadata]
        end;
        const md : contract_metadata = Big_map.update(parameter.token_id, Some(tm), acc.1.metadata);
    } with ((nil: list(operation)), acc.1 with record[metadata = md])
} with List.fold(add_entry, params, ((nil: list(operation)), store))

type closed_parameter is
    | Fa2 of fa2_entry_points
    | Asset of custom_entry_points

function fa2_main(const action: fa2_entry_points; const store : storage) : return is
    case action of
          Transfer (params) -> transfer (params, store)
        | Balance_of (params) -> balance_of (params, store)
    end

function custom_main(const action : custom_entry_points; const store : storage) : return is
    case action of
          Mint_id (params) -> mint_id (params, store)
        | Burn (_params) -> ((nil: list(operation)), store)
        | Create_entry (params) -> create_entry (params, store)
    end

function main(const action : closed_parameter; const store : storage) : return is
block {fail_on(Tezos.amount =/= 0tz, "XTZ_RECIEVED")
} with case action of
      Fa2 (params) -> fa2_main (params, store)
    | Asset (params) -> custom_main (params, store)
  end