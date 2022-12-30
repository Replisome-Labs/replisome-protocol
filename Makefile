-include .env

contractName = $(word 2,$(subst _, ,$1))

.PHONY: all test clean

all: clean remove install update build

# Clean the repo
clean:; forge clean

# Remove modules
remove:; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:; forge install foundry-rs/forge-std

# Update Dependencies
update:; forge update

build:; forge build

test:; forge test 

snapshot:; forge snapshot

slither:; slither ./src 

format:; prettier --write src/**/*.sol && prettier --write src/*.sol

# solhint should be installed globally
lint:; solhint src/**/*.sol && solhint src/*.sol

anvil:; anvil -m 'test test test test test test test test test test test junk'

# use the "@" to hide the command from your shell 
deploy-avalanche:; @forge script script/${contract}.s.sol:${contract} --rpc-url ${AVALANCHE_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -vvvv

# use the "@" to hide the command from your shell 
# deploy-fuji:; ./script/* 
    # for file in $^ ; do \
    #     echo "Hello" ; \
    # done

# This is the private key of account from the mnemonic from the "make anvil" command
deploy-anvil:; @forge script script/${contract}.s.sol:${contract} --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast 

# use the "@" to hide the command from your shell 
run-fuji:; @forge script script/${script}.s.sol:$(call contractName, ${script}) --rpc-url ${FUJI_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -vvvv

MYDIR = .
LIST = one two three
all:
	for i in $(LIST); do \
		echo $$i; \
	done
