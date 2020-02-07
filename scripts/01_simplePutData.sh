source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c '{"Args":["com.devcat.keyvalue:put", "first", "123"]}'
sleep 3 # waiting to propagte transactions to peer
$PEER3_EXEC peer chaincode query -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c '{"Args":["com.devcat.keyvalue:get", "first"]}'
$PEER3_EXEC peer chaincode query -C $CHANNEL_ALL_NAME -n $CHAINCODE_ZING -c '{"Args":["com.devcat.keyvalue:get", "first"]}'
$PEER1_EXEC peer chaincode query -C $CHANNEL12_NAME -n $CHAINCODE_RING -c '{"Args":["com.devcat.keyvalue:get", "first"]}'
