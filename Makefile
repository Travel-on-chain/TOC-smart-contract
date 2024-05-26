-include .env

.PHONY: all test clean deploy-anvil

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

NO_COMMIT := --no-commit

install :; forge install smartcontractkit/chainlink-brownie-contracts@1.1.0 $(NO_COMMIT) && forge install rari-capital/solmate $(NO_COMMIT) && forge install foundry-rs/forge-std $(NO_COMMIT) && forge install openzeppelin/openzeppelin-contracts@v4.9.6 $(NO_COMMIT) && forge install openzeppelin/openzeppelin-contracts-upgradeable@v4.9.6 $(NO_COMMIT) && forge install Cyfrin/foundry-devops --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

slither :; slither ./src 

format :; prettier --write src/**/*.sol && prettier --write src/*.sol

# solhint should be installed globally
lint :; solhint src/**/*.sol && solhint src/*.sol

anvil :; anvil -m 'test test test test test test test test test test test junk'

# use the "@" to hide the command from your shell 
deploy-sepolia :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${SEPOLIA_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}  -vvvv

# This is the private key of account from the mnemonic from the "make anvil" command
deploy-anvil:
	@forge script script/DeployBox.s.sol:DeployBox --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -vvvv
upgrade:
	@forge script script/UpgradeBox.s.sol:UpgradeBox --ffi --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -vvvv

deploy-all :; make deploy-${network} contract=APIConsumer && make deploy-${network} contract=KeepersCounter && make deploy-${network} contract=PriceFeedConsumer && make deploy-${network} contract=VRFConsumerV2

-include ${FCT_PLUGIN_PATH}/makefile-external

#1.部署操作步骤：
