import {Context, Contract} from 'fabric-contract-api';
import {ChaincodeStub} from 'fabric-shim';
import getBuffer from '../getBuffer';

export default class PingContract extends Contract {
    constructor() {
        super('com.devcat.ping');
    }

    public async instantiate() {
        // function which should be invoked when instantiate chaincode
    }

    public async ping(ctx: Context): Promise<string> {
        return 'pong ' + ctx.clientIdentity.getID();
    }

    public async putSomething(ctx: Context, key: string, value: string): Promise<string> {
        const stub: ChaincodeStub = ctx.stub;
        await stub.putState(key, new Buffer(value));
        return 'OK';
    }

    public async getSomething(ctx: Context, key: string): Promise<string> {
        const stub: ChaincodeStub = ctx.stub;
        const buffer = getBuffer(await stub.getState(key));

        const value = buffer.toString();
        if(value === '') {
            return 'NO RESULT FOR KEY'
        } else {
            return "Result for key is " + value;
        }
    }
}
