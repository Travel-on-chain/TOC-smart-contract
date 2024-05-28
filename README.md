# Travel on chain contracts

## Clone this repo

```shell
git clone https://github.com/Travel-on-chain/contract-core.git
```

## Install dependencies

```shell
make remove
make install
```

## Build contracts

```shell
make build
```

## Test contracts

```shell
make test
```

## Start local testing

1. Step1 

    ```shell
    make deploy-anvil
    ```

2. Step2 

    ```shell
    make upgrade
    ```
