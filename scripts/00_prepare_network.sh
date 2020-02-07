echo COMPOSE_PROJECT_NAME=net > .env

### npm-ing chaincode`s
(
  cd chaincode || exit 4
  npm install
  npm run build
)
###

source scripts/.env

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
(configtxgen -profile ${CHANNEL_ALL_PROFILE} -outputCreateChannelTx ./channel-artifacts/${CHANNEL_ALL_NAME}.tx -channelID $CHANNEL_ALL_NAME) &&
(configtxgen -profile ${CHANNEL12_PROFILE} -outputCreateChannelTx ./channel-artifacts/${CHANNEL12_NAME}.tx -channelID $CHANNEL12_NAME) &&

#generating anchor peer update file
(configtxgen -profile ${CHANNEL_ALL_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors_${CHANNEL_ALL_NAME}.tx -channelID $CHANNEL_ALL_NAME -asOrg Org1MSP) &&
(configtxgen -profile ${CHANNEL_ALL_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors_${CHANNEL_ALL_NAME}.tx -channelID $CHANNEL_ALL_NAME -asOrg Org2MSP) &&
(configtxgen -profile ${CHANNEL_ALL_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors_${CHANNEL_ALL_NAME}.tx -channelID $CHANNEL_ALL_NAME -asOrg Org3MSP) &&

(configtxgen -profile ${CHANNEL12_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors_${CHANNEL12_NAME}.tx -channelID $CHANNEL12_NAME -asOrg Org1MSP) &&
(configtxgen -profile ${CHANNEL12_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors_${CHANNEL12_NAME}.tx -channelID $CHANNEL12_NAME -asOrg Org2MSP) &&

# start infra
(docker-compose -f docker-compose.yaml up -d) &&

### joining channelAll
# create channel block file - it could be executed on any Peer
sleep 5
$PEER1_EXEC peer channel create -o orderer.orderer.com:7050 -c ${CHANNEL_ALL_NAME} -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_ALL_NAME}.tx
# join by Peer1
$PEER1_EXEC peer channel join -b ${CHANNEL_ALL_NAME}.block
$PEER1_EXEC peer channel update -o orderer.orderer.com:7050 -c ${CHANNEL_ALL_NAME} -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org1MSPanchors_${CHANNEL_ALL_NAME}.tx
# join by Peer2
$PEER2_EXEC peer channel join -b ${CHANNEL_ALL_NAME}.block
$PEER2_EXEC peer channel update -o orderer.orderer.com:7050 -c ${CHANNEL_ALL_NAME} -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org2MSPanchors_${CHANNEL_ALL_NAME}.tx
# join by Peer3
$PEER3_EXEC peer channel join -b ${CHANNEL_ALL_NAME}.block
$PEER3_EXEC peer channel update -o orderer.orderer.com:7050 -c ${CHANNEL_ALL_NAME} -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org3MSPanchors_${CHANNEL_ALL_NAME}.tx

### joining channel12
# create channel block file
($PEER1_EXEC peer channel create -o orderer.orderer.com:7050 -c $CHANNEL12_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL12_NAME}.tx ) &&
# join by Peer1
($PEER1_EXEC peer channel join -b ${CHANNEL12_NAME}.block ) &&
($PEER1_EXEC peer channel update -o orderer.orderer.com:7050 -c $CHANNEL12_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org1MSPanchors_${CHANNEL12_NAME}.tx ) &&
# join by Peer2
($PEER2_EXEC peer channel join -b ${CHANNEL12_NAME}.block ) &&
($PEER2_EXEC peer channel update -o orderer.orderer.com:7050 -c $CHANNEL12_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org2MSPanchors_${CHANNEL12_NAME}.tx ) &&

### installing chaincode on each peer
($PEER1_EXEC peer chaincode install -n $CHAINCODE_RING -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&
($PEER2_EXEC peer chaincode install -n $CHAINCODE_RING -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&
($PEER3_EXEC peer chaincode install -n $CHAINCODE_RING -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&

($PEER1_EXEC peer chaincode install -n $CHAINCODE_ZING -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&
#($PEER2_EXEC peer chaincode install -n $CHAINCODE_ZING -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&
($PEER3_EXEC peer chaincode install -n $CHAINCODE_ZING -p "/opt/gopath/src/github.com" -v 1.0 -l "node" ) &&

## instantiate chaincode
$PEER1_EXEC peer chaincode instantiate -n $CHAINCODE_RING -v 1.0 -l "node" -c '{"function":"instantiate","Args":[]}' -C $CHANNEL_ALL_NAME -P "OR('Org1MSP.peer', 'Org2MSP.peer', 'Org3MSP.peer')" -o orderer.orderer.com:7050
$PEER1_EXEC peer chaincode instantiate -n $CHAINCODE_RING -v 1.0 -l "node" -c '{"function":"instantiate","Args":[]}' -C $CHANNEL12_NAME -P "OR('Org1MSP.peer', 'Org2MSP.peer')" -o orderer.orderer.com:7050
$PEER1_EXEC peer chaincode instantiate -n $CHAINCODE_ZING -v 1.0 -l "node" -c '{"function":"instantiate","Args":[]}' -C $CHANNEL_ALL_NAME -P "OR('Org1MSP.peer', 'Org2MSP.peer', 'Org3MSP.peer')" -o orderer.orderer.com:7050
