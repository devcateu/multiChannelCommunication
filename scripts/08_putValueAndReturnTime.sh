source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:putValueAndReturnTime\", \"eighth\", \"watson\"]}" --peerAddresses peer0.org1.orderer.com:7051 --peerAddresses peer0.org2.orderer.com:7051 --peerAddresses peer0.org3.orderer.com:7051
sleep 3 # waiting to propagte transactions to peer
$PEER2_EXEC peer chaincode query -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"eighth\"]}"
