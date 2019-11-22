import {Context, Contract} from 'fabric-contract-api';

export default class AgentContract extends Contract {
    constructor() {
        super('com.devcat.agent');
    }

    public async instantiate() {
        // function which should be invoked when instantiate chaincode
    }

    public async ping(ctx: Context): Promise<string> {
        return 'Agent: ping';
    }
}
