import {Context, Contract} from 'fabric-contract-api';

export default class AgentPingContract extends Contract {
    constructor() {
        super('com.devcat.agentping');
    }

    public async instantiate() {
        // function which should be invoked when instantiate chaincode
    }

    public async ping(ctx: Context): Promise<string> {
        return 'Agent: ping';
    }
}
