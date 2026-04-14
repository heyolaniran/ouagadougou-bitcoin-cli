#!/bin/bash


# --- Configuration & Couleurs ---
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
RED='\033[0;31m'

set -e
function on_error {
    echo -e "${RED}Vous n'avez pas pu terminer votre histoire${NC}"
}
trap on_error ERR

echo -e "${BOLD}${YELLOW}======================================================"
echo -e "   BITCOIN CLI : LE SOULÈVEMENT DU 3 JANVIER 1966"
echo -e "======================================================${NC}\n"

# 1. Initialisation du portefeuille "Peuple"
echo -e "${CYAN}[Étape 1] Rassemblement à la Place d'Armes...${NC}"
bitcoin-cli -regtest createwallet "Peuple" > /dev/null 2>&1 || bitcoin-cli -regtest loadwallet "Peuple" > /dev/null 2>&1 || true
## METTEZ LE SCRIPT DE VOTRE HISTOIRE ICI
PEUPLE_ADDR=
echo -e "Identité du peuple créée. Adresse de collecte : ${BOLD}$PEUPLE_ADDR${NC}"

# Génération des fonds (101 blocs pour rendre le coinbase dépensable)
echo -e "Génération de la base monétaire (101 blocs)..."
bitcoin-cli -regtest -rpcwallet=Peuple generatetoaddress 101 $PEUPLE_ADDR > /dev/null
echo -e "${GREEN}Fonds prêts. Solde actuel : $(bitcoin-cli -regtest -rpcwallet=Peuple getbalance) BTC${NC}\n"

# 2. Le message historique dans la blockchain (OP_RETURN)
echo -e "${CYAN}[Étape 2] Gravure des revendications (OP_RETURN)...${NC}"
# Message : "Pain, Eau et Liberte"
MESSAGE_HEX="5061696e2c20456175206574204c696265727465"
DEST_ADDR=$(bitcoin-cli -regtest -rpcwallet=Peuple getnewaddress "Transition")

# Création de la transaction brute avec les bonnes entrées (fundrawtransaction)
RAW_TX=$(bitcoin-cli -regtest createrawtransaction \
    "[]" \
    "{\"$DEST_ADDR\":19.66, \"data\":\"$MESSAGE_HEX\"}")

FUNDED_TX=$(bitcoin-cli -regtest -rpcwallet=Peuple fundrawtransaction "$RAW_TX" | jq -r '.hex')

# Signature et Envoi
SIGNED_TX=$(bitcoin-cli -regtest -rpcwallet=Peuple signrawtransactionwithwallet "$FUNDED_TX" | jq -r '.hex')
FINAL_TXID=$(bitcoin-cli -regtest sendrawtransaction "$SIGNED_TX")

echo -e "Message gravé dans la transaction : ${BOLD}$FINAL_TXID${NC}"
echo -e "Statut : ${YELLOW}En attente dans le mempool (La rue gronde)${NC}\n"

# 3. Validation de la Transition (Chute de Yaméogo)
echo -e "${CYAN}[Étape 3] Démission de Maurice Yaméogo et Transition...${NC}"
echo -e "L'armée et le peuple valident le changement (Minage de 6 blocs)..."
BLOCK_HASH=$(bitcoin-cli -regtest -rpcwallet=Peuple generatetoaddress 6 $PEUPLE_ADDR | jq -r '.[0]')

# 4. Vérification finale
echo -e "${GREEN}Révolution réussie !${NC}"
echo -e "Le solde du portefeuille 'Peuple' a été mis à jour."
echo -e "Vérification du message caché dans la blockchain :"

# Extraction du message via getrawtransaction en passant le block hash
DECODED_MSG=$(bitcoin-cli -regtest getrawtransaction "$FINAL_TXID" true "$BLOCK_HASH" | jq -r '.vout[] | select(.scriptPubKey.type == "nulldata") | .scriptPubKey.asm' | cut -d' ' -f2)

echo -e "\n${BOLD}Message extrait (HEX) :${NC} $DECODED_MSG"
echo -e "${BOLD}Message traduit :${NC} $(echo $DECODED_MSG | xxd -r -p)"

echo -e "\n${YELLOW}------------------------------------------------------"
echo -e "L'histoire de la Haute-Volta est désormais immuable."
echo -e "3 Janvier 1966 : Le pouvoir appartient au peuple."
echo -e "------------------------------------------------------${NC}"
