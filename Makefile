install:
	npm install 

compile: 
	npm install && npx hardhat compile

test: 
	npx hardhat test

lint: 
	npm run lint

lint-check:
	npm run lint:check