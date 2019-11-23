source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_TWO_NAME -n $CHAINCODE_RING -c '{"Args":["com.devcat.keyvalue:put", "missionCode", "1642"]}'
sleep 3
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:getFrom\", \"missionCode\", \"$CHAINCODE_RING\", \"$CHANNEL_TWO_NAME\"]}"
