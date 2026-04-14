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

function require_filled {
    local name="$1"
    local value="$2"
    if [[ -z "$value" ]]; then
        echo -e "${RED}Complétez la variable ${BOLD}${name}${NC}${RED} dans enigme.sh avant de lancer le script.${NC}"
        exit 1
    fi
}

# ======================================================================
# MODE ENIGME:
# Completez chaque variable vide avec votre commande/resultat.
# Tant qu'une variable est vide, le script attend votre solution.
# ======================================================================

echo -e "${BOLD}${YELLOW}======================================================"
echo -e "   BITCOIN CLI : LE SOULÈVEMENT DU 3 JANVIER 1966"
echo -e "======================================================${NC}\n"

# 1. Initialisation du portefeuille "Peuple"
echo -e "${CYAN}[Étape 1] Rassemblement à la Place d'Armes...${NC}"
bitcoin-cli -regtest createwallet "Peuple" > /dev/null 2>&1 || bitcoin-cli -regtest loadwallet "Peuple" > /dev/null 2>&1 || true

# TODO: Remplacez par une commande qui retourne une adresse regtest valide.
PEUPLE_ADDR=
require_filled "PEUPLE_ADDR" "$PEUPLE_ADDR"

echo -e "Identité du peuple créée. Adresse de collecte : ${BOLD}$PEUPLE_ADDR${NC}"

# Génération des fonds (101 blocs pour rendre le coinbase dépensable)
echo -e "Génération de la base monétaire (101 blocs)..."
bitcoin-cli -regtest -rpcwallet=Peuple generatetoaddress 101 $PEUPLE_ADDR > /dev/null
echo -e "${GREEN}Fonds prêts. Solde actuel : $(bitcoin-cli -regtest -rpcwallet=Peuple getbalance) BTC${NC}\n"

# 2. Le message historique dans la blockchain (OP_RETURN)
echo -e "${CYAN}[Étape 2] Gravure des revendications (OP_RETURN)...${NC}"
# Message : "Pain, Eau et Liberte"
MESSAGE_HEX="5061696e2c20456175206574204c696265727465"

# TODO: Remplacez par une commande qui crée une nouvelle adresse de destination.
DEST_ADDR=
require_filled "DEST_ADDR" "$DEST_ADDR"

# Création de la transaction brute avec les bonnes entrées (fundrawtransaction)
# TODO: Remplacez par la commande createrawtransaction.
RAW_TX=
require_filled "RAW_TX" "$RAW_TX"

# TODO: Remplacez par la commande fundrawtransaction (extraire .hex).
FUNDED_TX=
require_filled "FUNDED_TX" "$FUNDED_TX"

# Signature et Envoi
# TODO: Remplacez par la commande signrawtransactionwithwallet (extraire .hex).
SIGNED_TX=
require_filled "SIGNED_TX" "$SIGNED_TX"

# TODO: Remplacez par la commande sendrawtransaction.
FINAL_TXID=
require_filled "FINAL_TXID" "$FINAL_TXID"

echo -e "Message gravé dans la transaction : ${BOLD}$FINAL_TXID${NC}"
echo -e "Statut : ${YELLOW}En attente dans le mempool (La rue gronde)${NC}\n"

# 3. Validation de la Transition (Chute de Yaméogo)
echo -e "${CYAN}[Étape 3] Démission de Maurice Yaméogo et Transition...${NC}"
echo -e "L'armée et le peuple valident le changement (Minage de 6 blocs)..."

# TODO: Remplacez par generatetoaddress puis extraire le premier hash de bloc.
BLOCK_HASH=
require_filled "BLOCK_HASH" "$BLOCK_HASH"

# 4. Vérification finale
echo -e "${GREEN}Révolution réussie !${NC}"
echo -e "Le solde du portefeuille 'Peuple' a été mis à jour."
echo -e "Vérification du message caché dans la blockchain :"

# Extraction du message via getrawtransaction en passant le block hash
# TODO: Remplacez par le pipeline getrawtransaction | jq | cut pour extraire l'HEX.
DECODED_MSG=
require_filled "DECODED_MSG" "$DECODED_MSG"

echo -e "\n${BOLD}Message extrait (HEX) :${NC} $DECODED_MSG"
echo -e "${BOLD}Message traduit :${NC} $(echo $DECODED_MSG | xxd -r -p)"

echo -e "\n${YELLOW}------------------------------------------------------"
echo -e "L'histoire de la Haute-Volta est désormais immuable."
echo -e "3 Janvier 1966 : Le pouvoir appartient au peuple."
echo -e "------------------------------------------------------${NC}"
