// function to bypass wrong typings in hyperledger testing lib
// see https://gerrit.hyperledger.org/r/c/fabric-chaincode-node/+/28356
// it fails when you want to execute real chaincode, it passes on tests
export default function getBuffer(buffer: Buffer) {
    if (typeof buffer['toBuffer'] === 'function') { // tslint:disable-line
        return buffer['toBuffer'](); // tslint:disable-line
    } else {
        return buffer;
    }
}
