# Dotferno - Dots are burning 😱

Private website to track DOT token burns of the [Polkadot Network](https://polkadot.network/) deployed at [dotferno.wtf](https://dotferno.wtf/).

## Architecture

Dotferno uses use a custom [Subquid Indexer](https://www.sqd.dev/) to index all relevant on-chain changes. It then queries those from the Elixir backend server and aggregates them into hourly and daily metrics. The results are then rendered with the Phoenix framework and served to the client.
