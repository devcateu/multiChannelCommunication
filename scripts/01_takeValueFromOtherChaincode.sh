source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ONE_NAME -n $CHAINCODE_ZING -c '{"Args":["com.devcat.keyvalue:put", "secretCode", "1000"]}'
sleep 3
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:getFrom\", \"secretCode\", \"$CHAINCODE_ZING\"]}"
