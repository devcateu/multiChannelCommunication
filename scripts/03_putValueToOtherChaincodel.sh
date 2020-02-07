source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:putHereAndTo\", \"third\", \"9458\", \"$CHAINCODE_ZING\"]}"
sleep 3 # waiting to propagte transactions to peer
echo "From RING:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"third\"]}"
echo "From ZING:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ALL_NAME -n $CHAINCODE_ZING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"third\"]}"

