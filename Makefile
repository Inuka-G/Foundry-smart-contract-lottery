-include .env

deploy:; forge script script/DeployRaffel.s.sol:DeployRaffel --rpc-url http://127.0.0.1:8545 --private-key $(ANVIL_PRIVATE_KEY) --broadcast -vvvv

enter:; cast send 0x95401dc811bb5740090279ba06cfa8fcf6113778 "enterRaffle()" --value 10000000000000000 --private-key $(ANVIL_PRIVATE_KEY) 

fundvrf:; cast send 

players0:; cast call 0x95401dc811bb5740090279ba06cfa8fcf6113778 "getPlayer(uint256)" "0"

winner:; cast call 0x95401dc811bb5740090279ba06cfa8fcf6113778 "getRecentWinner()"

game :; cast send 0x95401dc811bb5740090279ba06cfa8fcf6113778 "performUpkeep(bytes)" "0x00" --private-key $(ANVIL_PRIVATE_KEY) 

balance :; cast call 0x95401dc811bb5740090279ba06cfa8fcf6113778 "getTotalBalance()"

simulateWinner:; forge script script/DeployRaffel.s.sol:SimulateInterval --rpc-url http://127.0.0.1:8545 --private-key $(ANVIL_PRIVATE_KEY) --broadcast -vvvv