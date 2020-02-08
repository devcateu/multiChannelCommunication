source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c '{"Args":["com.devcat.keyvalue:put", "second", "1000"]}'
sleep 3 # waiting to propagte transaction to peers
$PEER1_EXEC peer chaincode query -C $CHANNEL_ALL_NAME -n $CHAINCODE_ZING -c "{\"Args\":[\"com.devcat.keyvalue:getFrom\", \"second\", \"$CHAINCODE_RING\"]}"
$PEER1_EXEC peer chaincode query -C $CHANNEL12_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:getFrom\", \"second\", \"$CHAINCODE_RING\", \"$CHANNEL_ALL_NAME\"]}"
