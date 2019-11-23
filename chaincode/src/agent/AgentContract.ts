import {Context, Contract} from 'fabric-contract-api';
import {KeyValueContract} from "../keyvalue";

export default class AgentContract extends Contract {
    constructor() {
        super('com.devcat.agent');
    }

    public async instantiate() {
        // function which should be invoked when instantiate chaincode
    }

    public async get(ctx: Context, key: string): Promise<string> {
        const keyValueContract = new KeyValueContract();
        const result = await keyValueContract.get(ctx, key);
        return "Agent see that KeyValueContract should return " + result;
    }
}
