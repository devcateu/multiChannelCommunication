source scripts/.env

$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:putHereAndTo\", \"cat-size\", \"9458\", \"$CHAINCODE_ZING\"]}" --tls --cafile $ORDERER_TLS_CERT
sleep 3
echo "RING is taking from ZING:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:getFrom\", \"cat-size\", \"$CHAINCODE_ZING\"]}" --tls --cafile $ORDERER_TLS_CERT
echo "RING is taking from RING:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_RING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"cat-size\"]}" --tls --cafile $ORDERER_TLS_CERT
echo "ZING is taking from RING:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_ZING -c "{\"Args\":[\"com.devcat.keyvalue:getFrom\", \"cat-size\", \"$CHAINCODE_RING\"]}" --tls --cafile $ORDERER_TLS_CERT
echo "ZING is taking from ZING:"
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_ZING -c "{\"Args\":[\"com.devcat.keyvalue:get\", \"cat-size\"]}" --tls --cafile $ORDERER_TLS_CERT

