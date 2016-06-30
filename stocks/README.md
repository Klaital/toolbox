# Klaital's Stock Tools
Simple commandline tools for checking my stocks. Uses Yahoo Finance JSON webservice.

Can be configured with stock positions from either a local Mongo instance, or a local json file.

## Docker instructions:

### Build:

```
docker build -t klaital/stock-positions .
docker run -t -i klaital/stock-positions ruby position.rb positions.json
```
