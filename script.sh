echo COMPOSE_PROJECT_NAME=net > .env

### npm-ing chaincode`s
(
  cd chaincode || exit 4
  npm install
  npm run build
)
###

export FABRIC_CFG_PATH=$PWD
export CHANNEL_ONE_NAME=channelall
export CHANNEL_ONE_PROFILE=ChannelAll
export CHANNEL_TWO_NAME=channel12
export CHANNEL_TWO_PROFILE=Channel12
export PEER1_EXEC='docker exec -e ORDERER_TLS_CERT=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem cli'
export PEER2_EXEC='docker exec -e ORDERER_TLS_CERT=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 cli'
export PEER3_EXEC='docker exec -e ORDERER_TLS_CERT=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -e CORE_PEER_LOCALMSPID=Org3MSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp -e CORE_PEER_ADDRESS=peer0.org3.example.com:7051 cli'
export ORDERER_TLS_CERT=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CHAINCODE_NAME=ping
export CHAINCODE_NAME_2=ping-manager

docker-compose -f docker-compose.yaml down

docker kill $(docker ps -a | grep orderer  | awk '{print $1}')
docker rm $(docker ps -a | grep orderer  | awk '{print $1}')
docker kill $(docker ps -a | grep ca  | awk '{print $1}')
docker rm $(docker ps -a | grep ca  | awk '{print $1}')
docker kill $(docker ps -a | grep cli  | awk '{print $1}')
docker rm $(docker ps -a | grep cli  | awk '{print $1}')
docker kill $(docker ps -a | grep peer  | awk '{print $1}')
docker rm $(docker ps -a | grep peer  | awk '{print $1}')
docker rm $(docker ps -a | grep dev  | awk '{print $1}')
docker rmi $(docker images dev-* -q)

rm -fr crypto-config
rm -fr channel-artifacts


# generating certificates
cryptogen generate --config=./crypto-config.yaml &&
for file in $(find crypto-config/ -iname *_sk); do dir=$(dirname $file); mv ${dir}/*_sk ${dir}/key.pem; done &&

mkdir channel-artifacts &&
# generating genesis block
configtxgen -profile OrdererGenesis -outputBlock ./channel-artifacts/genesis.block &&

# generating configuration for channels
(configtxgen -profile ${CHANNEL_ONE_PROFILE} -outputCreateChannelTx ./channel-artifacts/${CHANNEL_ONE_NAME}.tx -channelID $CHANNEL_ONE_NAME) &&
(configtxgen -profile ${CHANNEL_TWO_PROFILE} -outputCreateChannelTx ./channel-artifacts/${CHANNEL_TWO_NAME}.tx -channelID $CHANNEL_TWO_NAME) &&

#generating anchor peer update file
(configtxgen -profile ${CHANNEL_ONE_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors_${CHANNEL_ONE_NAME}.tx -channelID $CHANNEL_ONE_NAME -asOrg Org1MSP) &&
(configtxgen -profile ${CHANNEL_ONE_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors_${CHANNEL_ONE_NAME}.tx -channelID $CHANNEL_ONE_NAME -asOrg Org2MSP) &&
(configtxgen -profile ${CHANNEL_ONE_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors_${CHANNEL_ONE_NAME}.tx -channelID $CHANNEL_ONE_NAME -asOrg Org3MSP) &&

(configtxgen -profile ${CHANNEL_TWO_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors_${CHANNEL_TWO_NAME}.tx -channelID $CHANNEL_TWO_NAME -asOrg Org1MSP) &&
(configtxgen -profile ${CHANNEL_TWO_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors_${CHANNEL_TWO_NAME}.tx -channelID $CHANNEL_TWO_NAME -asOrg Org2MSP) &&

# start infra
(docker-compose -f docker-compose.yaml up -d) &&

### joining channelAll
# create channel block file - it could be executed on any Peer
sleep 5
$PEER1_EXEC peer channel create -o orderer.example.com:7050 -c ${CHANNEL_ONE_NAME} -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_ONE_NAME}.tx --tls --cafile $ORDERER_TLS_CERT
sleep 3
# join by Peer1
$PEER1_EXEC peer channel join -b ${CHANNEL_ONE_NAME}.block --tls --cafile $ORDERER_TLS_CERT
$PEER1_EXEC peer channel update -o orderer.example.com:7050 -c ${CHANNEL_ONE_NAME} -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org1MSPanchors_${CHANNEL_ONE_NAME}.tx --tls --cafile $ORDERER_TLS_CERT
# join by Peer2
$PEER2_EXEC peer channel join -b ${CHANNEL_ONE_NAME}.block --tls --cafile $ORDERER_TLS_CERT
$PEER2_EXEC peer channel update -o orderer.example.com:7050 -c ${CHANNEL_ONE_NAME} -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org2MSPanchors_${CHANNEL_ONE_NAME}.tx --tls --cafile $ORDERER_TLS_CERT
# join by Peer3
$PEER3_EXEC peer channel join -b ${CHANNEL_ONE_NAME}.block --tls --cafile $ORDERER_TLS_CERT
$PEER3_EXEC peer channel update -o orderer.example.com:7050 -c ${CHANNEL_ONE_NAME} -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org3MSPanchors_${CHANNEL_ONE_NAME}.tx --tls --cafile $ORDERER_TLS_CERT

### joining channel12
# create channel block file
($PEER1_EXEC peer channel create -o orderer.example.com:7050 -c $CHANNEL_TWO_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_TWO_NAME}.tx --tls --cafile $ORDERER_TLS_CERT ) &&

# join by Peer1
($PEER1_EXEC peer channel join -b ${CHANNEL_TWO_NAME}.block --tls --cafile $ORDERER_TLS_CERT ) &&
($PEER1_EXEC peer channel update -o orderer.example.com:7050 -c $CHANNEL_TWO_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org1MSPanchors_${CHANNEL_TWO_NAME}.tx --tls --cafile $ORDERER_TLS_CERT ) &&

# join by Peer2
($PEER2_EXEC peer channel join -b ${CHANNEL_TWO_NAME}.block --tls --cafile $ORDERER_TLS_CERT ) &&
($PEER2_EXEC peer channel update -o orderer.example.com:7050 -c $CHANNEL_TWO_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org2MSPanchors_${CHANNEL_TWO_NAME}.tx --tls --cafile $ORDERER_TLS_CERT ) &&
echo "joined" &&
### installing chaincode on each peer
($PEER1_EXEC peer chaincode install -n $CHAINCODE_NAME -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&
($PEER2_EXEC peer chaincode install -n $CHAINCODE_NAME -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&
($PEER3_EXEC peer chaincode install -n $CHAINCODE_NAME -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&

($PEER1_EXEC peer chaincode install -n $CHAINCODE_NAME_2 -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&
($PEER2_EXEC peer chaincode install -n $CHAINCODE_NAME_2 -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&
($PEER3_EXEC peer chaincode install -n $CHAINCODE_NAME_2 -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&
sleep 3 &&

## instantiate chaincode
$PEER1_EXEC peer chaincode instantiate -n $CHAINCODE_NAME -v 1.0 -l "node" -c '{"function":"instantiate","Args":[]}' -C $CHANNEL_ONE_NAME -P "OR('Org1MSP.peer', 'Org2MSP.peer', 'Org3MSP.peer')" -o orderer.example.com:7050 --tls --cafile $ORDERER_TLS_CERT
$PEER1_EXEC peer chaincode instantiate -n $CHAINCODE_NAME -v 1.0 -l "node" -c '{"function":"instantiate","Args":[]}' -C $CHANNEL_TWO_NAME -P "OR('Org1MSP.peer', 'Org2MSP.peer')" -o orderer.example.com:7050 --tls --cafile $ORDERER_TLS_CERT
$PEER1_EXEC peer chaincode instantiate -n $CHAINCODE_NAME_2 -v 1.0 -l "node" -c '{"function":"instantiate","Args":[]}' -C $CHANNEL_ONE_NAME -P "OR('Org1MSP.peer', 'Org2MSP.peer', 'Org3MSP.peer')" -o orderer.example.com:7050 --tls --cafile $ORDERER_TLS_CERT
sleep 3

# invoke & query CHANNEL 1
$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ONE_NAME -n $CHAINCODE_NAME -c '{"Args":["com.devcat.ping:putSomething", "slawomir", "1000"]}' --tls --cafile $ORDERER_TLS_CERT
sleep 3
echo "1: "
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_NAME -c '{"Args":["com.devcat.ping:getSomething", "slawomir"]}' --tls --cafile $ORDERER_TLS_CERT
echo "2: "
$PEER2_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_NAME -c '{"Args":["com.devcat.ping:getSomething", "slawomir"]}' --tls --cafile $ORDERER_TLS_CERT
echo "3: "
$PEER3_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_NAME -c '{"Args":["com.devcat.ping:getSomething", "slawomir"]}' --tls --cafile $ORDERER_TLS_CERT

# invoke & query CHANNEL 2
$PEER1_EXEC peer chaincode invoke -C $CHANNEL_TWO_NAME -n $CHAINCODE_NAME -c '{"Args":["com.devcat.ping:putSomething", "devcat", "flying cat"]}' --tls --cafile $ORDERER_TLS_CERT
sleep 3
echo "1: "
$PEER1_EXEC peer chaincode query -C $CHANNEL_TWO_NAME -n $CHAINCODE_NAME -c '{"Args":["com.devcat.ping:getSomething", "devcat"]}' --tls --cafile $ORDERER_TLS_CERT
echo "2: "
$PEER2_EXEC peer chaincode query -C $CHANNEL_TWO_NAME -n $CHAINCODE_NAME -c '{"Args":["com.devcat.ping:getSomething", "devcat"]}' --tls --cafile $ORDERER_TLS_CERT
echo "3: "
$PEER3_EXEC peer chaincode query -C $CHANNEL_TWO_NAME -n $CHAINCODE_NAME -c '{"Args":["com.devcat.ping:getSomething", "devcat"]}' --tls --cafile $ORDERER_TLS_CERT


# invoke & query CHANNEL 1 chaincode 2
$PEER1_EXEC peer chaincode invoke -C $CHANNEL_ONE_NAME -n $CHAINCODE_NAME_2 -c '{"Args":["com.devcat.ping:putSomething", "sml", "1000"]}' --tls --cafile $ORDERER_TLS_CERT
sleep 3
echo "1: "
$PEER1_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_NAME_2 -c '{"Args":["com.devcat.ping:getSomething", "sml"]}' --tls --cafile $ORDERER_TLS_CERT
echo "2: "
$PEER2_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_NAME_2 -c '{"Args":["com.devcat.ping:getSomething", "sml"]}' --tls --cafile $ORDERER_TLS_CERT
echo "3: "
$PEER3_EXEC peer chaincode query -C $CHANNEL_ONE_NAME -n $CHAINCODE_NAME_2 -c '{"Args":["com.devcat.ping:getSomething", "sml"]}' --tls --cafile $ORDERER_TLS_CERT
