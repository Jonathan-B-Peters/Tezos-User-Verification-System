import { importKey, InMemorySigner } from "@taquito/signer";
import { MichelCodecPacker, MichelsonMap, TezosToolkit } from "@taquito/taquito";
import { getTrailingCommentRanges } from "typescript";

const nftFA2JsonCode = require('../contracts/json/non-fungible-token.tz.json');

const accounts = require('../scripts/sandbox/accounts');

const useTestNet = true;

function getNftStorage() {
    const ledger = new MichelsonMap();
    const metadata = new MichelsonMap();

    const nftStorage = {
        ledger: ledger,
        next_token_id: 0,
        metadata: metadata
    }

    return nftStorage;
}

function getAlice() {
    return useTestNet ? accounts.alice_hangzhounet : accounts.alice;
}

function getRpc() {
    return useTestNet ? 'https://hangzhounet.api.tez.ie' : 'http://localhost:20000';
}

describe("First Test", function() {
    this.timeout(60000 * 5);

    let nft;
    const alice = getAlice();

    before(async() => {
        const tezos = new TezosToolkit(getRpc());
        if(useTestNet) {
            importKey(tezos, alice.email, alice.password, alice.mnemonic.join(' '), alice.activation_code);
        }
        else {
            tezos.setProvider({ signer: await InMemorySigner.fromSecretKey(alice.sk) });
        }
        tezos.setPackerProvider(new MichelCodecPacker());

        console.log("Originating NFT Contract...");

        await tezos.contract.originate({
            code: nftFA2JsonCode.text_code,
            storage: getNftStorage()
        }).then((originationOp) => {
            console.log(`Waiting for confirmation of origination of NFT: ${originationOp.contractAddress}...`);
            console.log(originationOp.contractAddress);
            return originationOp.contract();
        }).then((contract) => {
            console.log(`NFT origination completed.`);
            nft = contract;
        }).catch((error) => {
            console.log(`ERROR: ${error.stack}`);
            console.log(`ERROR: ${error.name}`);
            console.log(`ERROR: ${error.message}`);
        });
        console.log("NFT Initial Storage:");
        console.log(JSON.stringify(await nft.storage()));
        console.log(await nft.methods);
    })

    it("Succeeds at Minting NFTs for Alice.", async () => {
        const numNFTs = 1;
        console.log(`Minting ${numNFTs} NFTs for Alice...`);
        for(let i = 0; i < numNFTs; i++) {
            const op = await nft.methods.mint_id([alice.pkh]).send();
            await op.confirmation();
        }
        console.log("Printing Storage:");
        console.log(JSON.stringify(await nft.storage()));
    })

    it("Succeeds at Creating Entry for Alice.", async () => {
        console.log("Creating Entry for Alice...");
        const nats = new MichelsonMap();
        nats.set("Highscore", 10000);
        nats.set("Age", 22);
        const strings = new MichelsonMap();
        strings.set("Name", "Jonathan");
        const create_entry_params = [
            {
                token_id: 0,
                metadata: {
                    title: "First Entry!",
                    nats: nats,
                    strings: strings
                }
            }
        ]
        console.log(JSON.stringify(nft.parameterSchema.ExtractSignatures(), null, 2));
        const op = await nft.methods.create_entry(create_entry_params).send();
        await op.confirmation();
        console.log("Printing Storage:");
        console.log(JSON.stringify(await nft.storage()));
    })
})