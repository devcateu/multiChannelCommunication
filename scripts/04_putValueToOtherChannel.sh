source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:putHereAndTo\", \"fourth\", \"3215\", \"$CHAINCODE_RING\", \"$CHANNEL12_NAME\"]}"
sleep 3 # waiting to propagte transactions to peer
echo "ChannelAll:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ALL_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"fourth\"]}"
echo "Channel12:"
$PEER1_EXEC peer chaincode query -C $CHANNEL12_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"fourth\"]}"
