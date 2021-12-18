type token_id is nat

type transfer_destination is
    [@layout:comb]
    record [
        to_         : address;
        token_id    : token_id;
        amount      : nat
    ]

type transfer_param is
    [@layout:comb]
    record [
        from_   : address;
        txs     : list(transfer_destination)
    ]

type transfer_params is list(transfer_param)

type balance_of_request is
    [@layout:comb]
    record [
        owner       : address;
        token_id    : token_id;
    ]

type balance_of_response is
    [@layout:comb]
    record [
        request     : balance_of_request;
        balance     : nat
    ]

type balance_of_params is
    [@layout:comb]
    record [
        requests      : list(balance_of_request);
        callback    : contract(list(balance_of_response))
    ]

type fa2_entry_points is
      Transfer  of transfer_params
    | Balance_of of balance_of_params