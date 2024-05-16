# Compose zkverify simplified

This repository contains all the resources for deploying a zkverify rpc, validator, or boot nodes, on testnet.


## Project overview

There are three types of nodes that can be deployed:

1. Rpc node
2. Validator node
3. Boot node

When using any of the scripts provided in this repository, it will be requested to select **node type** and the **network** to run (testnet).

---

## Requirements

* docker
* docker compose
* jq
* gnu-sed for Darwin distribution

---

## Installation instructions

Run the init.sh script and follow the instructions in order to prepare the deployment for the first time.

```shell
./scripts/init.sh
```

The script will generate the required deployment files under the [deployments](deployments) directory.

### Boot node

This repository provides the boot node's P2P configuration for WebSocket (WS) and TCP protocols. 
For implementing secure WebSocket protocol (WSS) support for P2P communication, please refer to the official documentation [here](https://wiki.polkadot.network/docs/maintain-bootnode).

### Update

When a new version of the node is released this project will be updated with the new version modified in the `.env.*.template` files.

There may also be other changes to environment variables or configuration files that may need to be updated.

In order to update the project to the new version:

1. Pull the latest changes from the repository.
2. Run the [update.sh](./scripts/update.sh) script.

```shell
./scripts/update.sh
```

Should the script prompt you to update some of the values in .env file, it is recommended to accept all the changes
unless you know what you are doing.

---

## Usage Guide

### Start

Run the [start.sh](./scripts/start.sh) script to start the node.

```shell
./scripts/start.sh
```

### Stop

Run the [stop.sh](./scripts/stop.sh) script to just stop, or stop and delete the node.

```shell
./scripts/stop.sh
```

---

## Contributing Guidelines

Please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file for information on how to contribute to this project.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

