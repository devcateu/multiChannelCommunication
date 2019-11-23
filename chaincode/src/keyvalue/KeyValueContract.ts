import {Context, Contract} from 'fabric-contract-api';
import {ChaincodeStub} from 'fabric-shim';
import getBuffer from '../getBuffer';

export default class KeyValueContract extends Contract {
    constructor() {
        super('com.devcat.keyvalue');
    }

    public async instantiate() {
        // function which should be invoked when instantiate chaincode
    }

    public async put(ctx: Context, key: string, value: string): Promise<string> {
        const stub: ChaincodeStub = ctx.stub;
        await stub.putState(key, new Buffer(value));
        return 'OK';
    }

    public async putTime(ctx: Context, key: string): Promise<string> {
        const stub: ChaincodeStub = ctx.stub;
        await stub.putState(key, new Buffer("" + Date.now()));
        return 'OK';
    }

    public async putValueAndReturnTime(ctx: Context, key: string, value: string): Promise<string> {
        const stub: ChaincodeStub = ctx.stub;
        await stub.putState(key, new Buffer(value));
        return 'OK'  + Date.now();
    }

    public async get(ctx: Context, key: string): Promise<string> {
        const stub: ChaincodeStub = ctx.stub;
        const buffer = getBuffer(await stub.getState(key));

        const value = buffer.toString();
        if(value === '') {
            return 'NO RESULT FOR KEY'
        } else {
            return "Result for key is " + value;
        }
    }

    public async getFrom(ctx: Context, key: string, chaincode: string, channel: string): Promise<string> {
        const stub: ChaincodeStub = ctx.stub;
        let response = await stub.invokeChaincode(chaincode, ['com.devcat.keyvalue:get', key], channel);
        return getBuffer(response.payload).toString()
    }

    public async putHereAndTo(ctx: Context, key: string, value: string, chaincode: string, channel: string): Promise<string> {
        let thisResult = await this.put(ctx, key, value);
        const stub: ChaincodeStub = ctx.stub;
        let response = await stub.invokeChaincode(chaincode, ['com.devcat.keyvalue:put', key, value], channel);
        return 'Result local: "' + thisResult  + '" ; result remote: "' + getBuffer(response.payload).toString() + '"';
    }
}
