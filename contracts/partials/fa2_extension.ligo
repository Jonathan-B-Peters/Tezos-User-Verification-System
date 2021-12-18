type token_metadata_entry is
[@layout:comb]
record [
    title: string;
    nats: map(string, nat);
    strings: map(string, string);
]

type token_metadata is map(string, token_metadata_entry)

type mint_param is
[@layout:comb]
record [
    to_ : address;
]

type mint_params is list(mint_param)

type burn_params is list(nat)

type create_entry_param is
[@layout:comb]
record [
    token_id: token_id;
    metadata: token_metadata_entry
]

type create_entry_params is list(create_entry_param)

type custom_entry_points is
| Mint_id of mint_params
| Burn of burn_params
| Create_entry of create_entry_params