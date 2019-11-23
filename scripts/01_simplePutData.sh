source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ONE_NAME -n $CHAINCODE_ZING -c '{"Args":["com.devcat.keyvalue:put", "slk", "123"]}'
sleep 3
$PEER3_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_ZING -c '{"Args":["com.devcat.keyvalue:get", "slk"]}'
$PEER3_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c '{"Args":["com.devcat.keyvalue:get", "slk"]}'
