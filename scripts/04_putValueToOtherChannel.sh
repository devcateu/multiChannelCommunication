source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:putHereAndTo\", \"dog-size\", \"3215\", \"$CHAINCODE_RING\", \"$CHANNEL_TWO_NAME\"]}"
sleep 3
echo "Channel One is taking from Channel Two:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:getFrom\", \"dog-size\", \"$CHAINCODE_RING\", \"$CHANNEL_TWO_NAME\"]}"
echo "Channel One is taking from Channel Two:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"dog-size\"]}"
echo "Channel Two is taking from Channel One:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_TWO_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:getFrom\", \"dog-size\", \"$CHAINCODE_RING\", \"$CHANNEL_ONE_NAME\"]}"
echo "Channel Two is taking from Channel Two:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_TWO_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"dog-size\"]}"
