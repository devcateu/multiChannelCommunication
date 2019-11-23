source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:put\", \"withoutName\", \"Frankenstein\"]}" --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051
sleep 3
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"get\", \"withoutName\"]}"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"withoutName\"]}"
