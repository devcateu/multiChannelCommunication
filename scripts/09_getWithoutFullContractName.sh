source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:put\", \"ninth\", \"Frankenstein\"]}"
sleep 3 # waiting to propagte transactions to peer
$PEER1_EXEC peer chaincode query -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"get\", \"ninth\"]}"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"ninth\"]}"
