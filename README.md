# Documentation detaillee de `enigme.sh`

Ce document explique en detail les commandes utilisees dans le script `enigme.sh`, leur role, ainsi que le **type des arguments** attendus.

## 1) Objectif du script

Le script met en scene une histoire sur un noeud Bitcoin en mode `regtest` et enchaine les operations suivantes :

1. creation/chargement d'un wallet `Peuple`
2. generation de blocs pour obtenir des fonds depensables
3. creation d'une transaction avec un message `OP_RETURN`
4. signature et diffusion de la transaction
5. minage de blocs de confirmation
6. relecture du message en blockchain

## 2) Prerequis

- `bash`
- `bitcoin-cli` connecte a un noeud Bitcoin en fonctionnement
- mode `regtest` actif
- `jq` (pour extraire des champs JSON)
- `xxd` (pour convertir HEX vers texte)

## 3) Point important a corriger avant execution

Dans `enigme.sh`, la variable suivante doit recevoir une adresse valide :

```bash
PEUPLE_ADDR=
```

Exemple :

```bash
PEUPLE_ADDR=$(bitcoin-cli -regtest -rpcwallet=Peuple getnewaddress "Peuple")
```

Sans cette valeur, les commandes de minage avec `generatetoaddress` echoueront.

## 4) Commandes utilisees et types d'arguments

### 4.1 Creation/chargement du wallet

Commande :

```bash
bitcoin-cli -regtest createwallet "Peuple"
```

- `-regtest` : **option/flag** (booleen, pas de valeur supplementaire)
- `createwallet` : **commande RPC** (chaine fixe)
- `"Peuple"` : **string** (nom du wallet)

Commande de repli :

```bash
bitcoin-cli -regtest loadwallet "Peuple"
```

- `loadwallet` : **commande RPC**
- `"Peuple"` : **string** (nom d'un wallet existant)

### 4.2 Minage initial pour obtenir des fonds depensables

Commande :

```bash
bitcoin-cli -regtest -rpcwallet=Peuple generatetoaddress 101 $PEUPLE_ADDR
```

- `-rpcwallet=Peuple` : **option cle=valeur** (string apres `=`)
- `generatetoaddress` : **commande RPC**
- `101` : **integer** (nombre de blocs a miner)
- `$PEUPLE_ADDR` : **string** (adresse Bitcoin valide en regtest)

### 4.3 Verification du solde

Commande :

```bash
bitcoin-cli -regtest -rpcwallet=Peuple getbalance
```

- `getbalance` : **commande RPC**
- sortie attendue : **nombre decimal** (BTC)

### 4.4 Generation d'une adresse de destination

Commande :

```bash
bitcoin-cli -regtest -rpcwallet=Peuple getnewaddress "Transition"
```

- `"Transition"` : **string** (label associe a l'adresse)
- sortie attendue : **string** (adresse Bitcoin)

### 4.5 Creation d'une transaction brute avec OP_RETURN

Commande :

```bash
bitcoin-cli -regtest createrawtransaction "[]" "{\"$DEST_ADDR\":19.66, \"data\":\"$MESSAGE_HEX\"}"
```

Arguments :

- `"[]"` : **JSON array encode en string**
  - liste des entrees (inputs) vide ici, car les UTXO seront choisis ensuite par `fundrawtransaction`
- `"{\"$DEST_ADDR\":19.66, \"data\":\"$MESSAGE_HEX\"}"` : **JSON object encode en string**
  - `"$DEST_ADDR":19.66` : cle `string` (adresse) + valeur `number` (montant en BTC)
  - `"data":"$MESSAGE_HEX"` : cle `string` + valeur `string` hexadecimale (payload OP_RETURN)

Sortie attendue : **string hex** (transaction brute non financee).

### 4.6 Financement automatique de la transaction

Commande :

```bash
bitcoin-cli -regtest -rpcwallet=Peuple fundrawtransaction "$RAW_TX"
```

- `"$RAW_TX"` : **string hex** (transaction brute)
- sortie : **JSON object** contenant notamment :
  - `hex` (**string**) : transaction brute financee
  - `fee` (**number**) : frais estimes
  - `changepos` (**integer**) : position de la sortie de change

Extraction dans le script :

```bash
jq -r '.hex'
```

- filtre `jq` retourne une **string**.

### 4.7 Signature de la transaction

Commande :

```bash
bitcoin-cli -regtest -rpcwallet=Peuple signrawtransactionwithwallet "$FUNDED_TX"
```

- `"$FUNDED_TX"` : **string hex**
- sortie : **JSON object** avec :
  - `hex` (**string**) : tx signee
  - `complete` (**boolean**) : signature complete ou non

### 4.8 Diffusion de la transaction

Commande :

```bash
bitcoin-cli -regtest sendrawtransaction "$SIGNED_TX"
```

- `"$SIGNED_TX"` : **string hex**
- sortie : **string** (txid)

### 4.9 Minage de confirmation

Commande :

```bash
bitcoin-cli -regtest -rpcwallet=Peuple generatetoaddress 6 $PEUPLE_ADDR
```

- `6` : **integer** (nombre de blocs de confirmation souhaites)
- sortie : **JSON array de strings** (hashs de blocs)

Extraction du premier hash :

```bash
jq -r '.[0]'
```

- `.[0]` : premier element du tableau
- type retourne : **string** (block hash)

### 4.10 Lecture de la transaction et extraction du message OP_RETURN

Commande :

```bash
bitcoin-cli -regtest getrawtransaction "$FINAL_TXID" true "$BLOCK_HASH"
```

Arguments :

- `"$FINAL_TXID"` : **string** (identifiant de transaction)
- `true` : **boolean** (demande la sortie decodee JSON, verbose)
- `"$BLOCK_HASH"` : **string** (hash du bloc contenant la transaction)

Le pipeline d'extraction :

```bash
jq -r '.vout[] | select(.scriptPubKey.type == "nulldata") | .scriptPubKey.asm' | cut -d' ' -f2
```

- `jq` :
  - parcourt `vout` (tableau)
  - filtre `scriptPubKey.type == "nulldata"` (sortie OP_RETURN)
  - recupere `asm` (**string**)
- `cut -d' ' -f2` :
  - `-d' '` : separateur **char**
  - `-f2` : champ **integer**
  - resultat : payload HEX (**string**)

### 4.11 Conversion HEX -> texte

Commande :

```bash
echo $DECODED_MSG | xxd -r -p
```

- `$DECODED_MSG` : **string hex**
- `xxd -r -p` :
  - `-r` inverse le dump hex -> binaire
  - `-p` format plain hexdump
- sortie : **string texte**

## 5) Variables principales du script

- `PEUPLE_ADDR` : **string** (adresse Bitcoin regtest)
- `MESSAGE_HEX` : **string** hexadecimale
- `DEST_ADDR` : **string** (adresse Bitcoin)
- `RAW_TX` : **string** hex (tx brute)
- `FUNDED_TX` : **string** hex (tx financee)
- `SIGNED_TX` : **string** hex (tx signee)
- `FINAL_TXID` : **string** (identifiant tx)
- `BLOCK_HASH` : **string** (hash bloc)
- `DECODED_MSG` : **string** (hex extrait de OP_RETURN)

## 6) Lancement

1. Verifier que le noeud Bitcoin est demarre en `regtest`.
2. Completer la variable `PEUPLE_ADDR` dans `enigme.sh`.
3. Rendre le script executable :

```bash
chmod +x enigme.sh
```

4. Executer :

```bash
./enigme.sh
```

## 7) Erreurs courantes

- **Adresse vide/invalide** : `PEUPLE_ADDR` non renseignee.
- **Wallet absent** : `loadwallet` echoue si le wallet n'existe pas encore.
- **`jq` manquant** : extraction JSON impossible.
- **Noeud non lance en regtest** : toutes les commandes `-regtest` echouent.

## 8) Resume rapide des types d'arguments

- `string` : nom de wallet, adresses, txid, hash bloc, hex
- `integer` : nombre de blocs (`101`, `6`)
- `number` : montants BTC (`19.66`)
- `boolean` : mode verbose (`true`)
- `JSON string` : objets/tableaux passes a certaines RPC (`createrawtransaction`)
