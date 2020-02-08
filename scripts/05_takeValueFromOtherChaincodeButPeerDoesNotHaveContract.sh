source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ALL_NAME -n $CHAINCODE_ZING -c '{"Args":["com.devcat.keyvalue:put", "fifth", "1000"]}'
sleep 3 # waiting to propagte transaction to peers
$PEER2_EXEC peer chaincode query -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:getFrom\", \"fifth\", \"$CHAINCODE_ZING\"]}"
