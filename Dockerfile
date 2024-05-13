# Use Golang base image
FROM golang:1.20

# Set variables
ENV MONIKER=NixxGuardian
ENV CONFIG_TOML=/root/.mantrachain/config/config.toml
ENV SEEDS=d6016af7cb20cf1905bd61468f6a61decb3fd7c0@34.72.142.50:26656
ENV PEERS=da061f404690c5b6b19dd85d40fefde1fecf406c@34.68.19.19:26656,20db08acbcac9b7114839e63539da2802b848982@34.72.148.3:26656

# Install necessary packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y curl git jq lz4 build-essential unzip wget

# Install binary
RUN mkdir /root/bin
WORKDIR /root/bin
ADD https://github.com/MANTRA-Finance/public/raw/main/mantrachain-hongbai/mantrachaind-linux-amd64.zip .
RUN unzip mantrachaind-linux-amd64.zip && \
    rm -rf mantrachaind-linux-amd64.zip

# Install cosmwasm library
ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.3.1/libwasmvm.x86_64.so /usr/lib/

# Initialize node
RUN /root/bin/mantrachaind init $MONIKER --chain-id mantra-hongbai-1

# Download "genesis.json" - HONGBAI
RUN curl -Ls https://github.com/MANTRA-Finance/public/raw/main/mantrachain-hongbai/genesis.json > /root/.mantrachain/config/genesis.json

# Update the config.toml with the seed node and the peers for the MANTRA Hongbai Chain (Testnet)
RUN sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $CONFIG_TOML && \
    sed -i.bak -e "s/^seeds =.*/seeds = \"$SEEDS\"/" $CONFIG_TOML && \
    sed -i.bak -e "s/^external_address *=.*/external_address = \"$(wget -qO- eth0.me):26656\"/" $CONFIG_TOML && \
    sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0002uom"|g' $CONFIG_TOML && \
    sed -i 's|^prometheus *=.*|prometheus = true|' $CONFIG_TOML

# Install cosmovisor
RUN go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.4.0 && \
    mkdir -p /root/.mantrachain/cosmovisor/genesis/bin && \
    mkdir -p /root/.mantrachain/cosmovisor/upgrades && \
    mkdir -p /root/.mantrachain/cosmovisor/data_backup && \
    cp /root/bin/mantrachaind /root/.mantrachain/cosmovisor/genesis/bin

# Setup the command to start the node
CMD ["cosmovisor", "run", "start"]
