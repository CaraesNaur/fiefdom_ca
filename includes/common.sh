#!/bin/bash

HOST_DOMAIN_MATCH="^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9]*.?)*[A-Za-z0-9]+$"
HOST_MATCH="^[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]+$"

CA_CONFIG_FILE="certificate_authority.conf"

ROOT_CA_FULLNAME=Root
ROOT_CA_REFNAME=root

INTM_CA_FULLNAME=Intermediate
INTM_CA_REFNAME=intm

CA_KEY_FILE_BASE="_ca.key.pem"
CA_CSR_FILE_BASE="_ca.csr.pem"
CA_CERT_FILE_BASE="_ca.cert.pem"
CA_CRL_FILE_BASE="_ca.crl.pem"
CA_CHAIN_FILE_BASE="_ca_chain.cert.pem"

HOSTS_KEY_FILE_BASE="_host_key.pem"
HOSTS_CSR_FILE_BASE="_host_csr.pem"
HOSTS_CRT_FILE_BASE="_host_crt.pem"
HOSTS_CONFIG_FILE_BASE="_openssl.cnf"

CA_DEPLOYMENTS_FILE_BARE="crt_deploy.ini"

HOST_CERT_DAYS_DEFAULT=397

declare DN_PROMPTS_LIST=( "countryName" "stateOrProvinceName" "localityName" "0.organizationName" "organizationalUnitName" "emailAddress" );

declare -rA DN_PROMPTS=(
	["countryName"]="Country Name (2 letter code)"
	["stateOrProvinceName"]="State or Province Name"
	["localityName"]="Locality Name"
	["0.organizationName"]="Organization Name"
	["organizationalUnitName"]="Organizational Unit Name"
	["emailAddress"]="Email Address"
);

declare -rA HDN_PROMPTS=(
	["C"]="Country Name (2 letter code)"
	["ST"]="State or Province Name"
	["L"]="Locality Name"
	["O"]="Organization Name"
	["OU"]="Organizational Unit Name"
)

declare HDN_PROMPTS_LIST=( "C" "ST" "L" "O" "OU" )

declare -A HOST_CONFIG_MAP=(
	["C"]="HOST_DEFAULT_COUNTRY"
	["ST"]="HOST_DEFAULT_PROVINCE"
	["L"]="HOST_DEFAULT_LOCALITY"
	["O"]="HOST_DEFAULT_ORG_NAME"
	["OU"]="HOST_DEFAULT_ORG_UNIT_NAME"
)

declare -A HOST_INTM_DN_MAP=(
	["C"]="countryName_default"
	["ST"]="stateOrProvinceName_default"
	["L"]="localityName_default"
	["O"]="0.organizationName_default"
	["OU"]="organizationalUnitName_default"
)


# Colors on default
C_BLACK='\033[0;49;30m' # BLACK on DEFAULT RS
C_RED='\033[0;49;31m' # RED on DEFAULT RS
C_GREEN='\033[0;49;32m' # GREEN on DEFAULT RS
C_YELLOW='\033[0;49;33m' # YELLOW on DEFAULT RS
C_BLUE='\033[0;49;34m' # BLUE on DEFAULT RS
C_MAGENTA='\033[0;49;35m' # MAGENTA on DEFAULT RS
C_CYAN='\033[0;49;36m' # CYAN on DEFAULT RS
C_WHITE='\033[0;49;37m' # WHITE on DEFAULT RS

C_MAGENTA_BLUE_HD='\033[8;44;35m' # MAGENTA on BLUE (hidden)
C_MAGENTA_BLUE_RV='\033[7;44;35m' # MAGENTA on BLUE (reversed)
C_MAGENTA_BLUE_BL='\033[5;44;35m' # MAGENTA on BLUE (blinking)
C_MAGENTA_BLUE_UL='\033[4;44;35m' # MAGENTA on BLUE (underlined)
C_MAGENTA_BLUE_DM='\033[2;44;35m' # MAGENTA on BLUE (dimmed)
C_MAGENTA_BLUE_BD='\033[1;44;35m' # MAGENTA on BLUE (bold/bright)
C_MAGENTA_BLUE='\033[0;44;35m' # MAGENTA on BLUE (normal)

C_CYAN_BLUE_HD='\033[8;44;36m' # CYAN on BLUE (hidden)
C_CYAN_BLUE_RV='\033[7;44;36m' # CYAN on BLUE (reversed)
C_CYAN_BLUE_BL='\033[5;44;36m' # CYAN on BLUE (blinking)
C_CYAN_BLUE_UL='\033[4;44;36m' # CYAN on BLUE (underlined)
C_CYAN_BLUE_DM='\033[2;44;36m' # CYAN on BLUE (dimmed)
C_CYAN_BLUE_BD='\033[1;44;36m' # CYAN on BLUE (bold/bright)
C_CYAN_BLUE='\033[0;44;36m' # CYAN on BLUE (normal)

C_WHITE_BLUE_HD='\033[8;44;37m' # WHITE on BLUE (hidden)
C_WHITE_BLUE_RV='\033[7;44;37m' # WHITE on BLUE (reversed)
C_WHITE_BLUE_BL='\033[5;44;37m' # WHITE on BLUE (blinking)
C_WHITE_BLUE_UL='\033[4;44;37m' # WHITE on BLUE (underlined)
C_WHITE_BLUE_DM='\033[2;44;37m' # WHITE on BLUE (dimmed)
C_WHITE_BLUE_BD='\033[1;44;37m' # WHITE on BLUE (bold/bright)
C_WHITE_BLUE='\033[0;44;37m' # WHITE on BLUE (normal)

C_BLACK_BLUE_HD='\033[8;44;30m' # BLACK on BLUE (hidden)
C_BLACK_BLUE_RV='\033[7;44;30m' # BLACK on BLUE (reversed)
C_BLACK_BLUE_BL='\033[5;44;30m' # BLACK on BLUE (blinking)
C_BLACK_BLUE_UL='\033[4;44;30m' # BLACK on BLUE (underlined)
C_BLACK_BLUE_DM='\033[2;44;30m' # BLACK on BLUE (dimmed)
C_BLACK_BLUE_BD='\033[1;44;30m' # BLACK on BLUE (bold/bright)
C_BLACK_BLUE='\033[0;44;30m' # BLACK on BLUE (normal)

C_RED_BLUE_HD='\033[8;44;31m' # RED on BLUE (hidden)
C_RED_BLUE_RV='\033[7;44;31m' # RED on BLUE (reversed)
C_RED_BLUE_BL='\033[5;44;31m' # RED on BLUE (blinking)
C_RED_BLUE_UL='\033[4;44;31m' # RED on BLUE (underlined)
C_RED_BLUE_DM='\033[2;44;31m' # RED on BLUE (dimmed)
C_RED_BLUE_BD='\033[1;44;31m' # RED on BLUE (bold/bright)
C_RED_BLUE='\033[0;44;31m' # RED on BLUE (normal)

C_GREEN_BLUE_HD='\033[8;44;32m' # GREEN on BLUE (hidden)
C_GREEN_BLUE_RV='\033[7;44;32m' # GREEN on BLUE (reversed)
C_GREEN_BLUE_BL='\033[5;44;32m' # GREEN on BLUE (blinking)
C_GREEN_BLUE_UL='\033[4;44;32m' # GREEN on BLUE (underlined)
C_GREEN_BLUE_DM='\033[2;44;32m' # GREEN on BLUE (dimmed)
C_GREEN_BLUE_BD='\033[1;44;32m' # GREEN on BLUE (bold/bright)
C_GREEN_BLUE='\033[0;44;32m' # GREEN on BLUE (normal)

C_YELLOW_BLUE_HD='\033[8;44;33m' # YELLOW on BLUE (hidden)
C_YELLOW_BLUE_RV='\033[7;44;33m' # YELLOW on BLUE (reversed)
C_YELLOW_BLUE_BL='\033[5;44;33m' # YELLOW on BLUE (blinking)
C_YELLOW_BLUE_UL='\033[4;44;33m' # YELLOW on BLUE (underlined)
C_YELLOW_BLUE_DM='\033[2;44;33m' # YELLOW on BLUE (dimmed)
C_YELLOW_BLUE_BD='\033[1;44;33m' # YELLOW on BLUE (bold/bright)
C_YELLOW_BLUE='\033[0;44;33m' # YELLOW on BLUE (normal)

C_DEFAULT_BLUE_HD='\033[8;44;39m' # DEFAULT on BLUE (hidden)
C_DEFAULT_BLUE_RV='\033[7;44;39m' # DEFAULT on BLUE (reversed)
C_DEFAULT_BLUE_BL='\033[5;44;39m' # DEFAULT on BLUE (blinking)
C_DEFAULT_BLUE_UL='\033[4;44;39m' # DEFAULT on BLUE (underlined)
C_DEFAULT_BLUE_DM='\033[2;44;39m' # DEFAULT on BLUE (dimmed)
C_DEFAULT_BLUE_BD='\033[1;44;39m' # DEFAULT on BLUE (bold/bright)
C_DEFAULT_BLUE='\033[0;44;39m' # DEFAULT on BLUE (normal)

C_BLUE_MAGENTA_HD='\033[8;45;34m' # BLUE on MAGENTA (hidden)
C_BLUE_MAGENTA_RV='\033[7;45;34m' # BLUE on MAGENTA (reversed)
C_BLUE_MAGENTA_BL='\033[5;45;34m' # BLUE on MAGENTA (blinking)
C_BLUE_MAGENTA_UL='\033[4;45;34m' # BLUE on MAGENTA (underlined)
C_BLUE_MAGENTA_DM='\033[2;45;34m' # BLUE on MAGENTA (dimmed)
C_BLUE_MAGENTA_BD='\033[1;45;34m' # BLUE on MAGENTA (bold/bright)
C_BLUE_MAGENTA='\033[0;45;34m' # BLUE on MAGENTA (normal)


C_CYAN_MAGENTA_HD='\033[8;45;36m' # CYAN on MAGENTA (hidden)
C_CYAN_MAGENTA_RV='\033[7;45;36m' # CYAN on MAGENTA (reversed)
C_CYAN_MAGENTA_BL='\033[5;45;36m' # CYAN on MAGENTA (blinking)
C_CYAN_MAGENTA_UL='\033[4;45;36m' # CYAN on MAGENTA (underlined)
C_CYAN_MAGENTA_DM='\033[2;45;36m' # CYAN on MAGENTA (dimmed)
C_CYAN_MAGENTA_BD='\033[1;45;36m' # CYAN on MAGENTA (bold/bright)
C_CYAN_MAGENTA='\033[0;45;36m' # CYAN on MAGENTA (normal)

C_WHITE_MAGENTA_HD='\033[8;45;37m' # WHITE on MAGENTA (hidden)
C_WHITE_MAGENTA_RV='\033[7;45;37m' # WHITE on MAGENTA (reversed)
C_WHITE_MAGENTA_BL='\033[5;45;37m' # WHITE on MAGENTA (blinking)
C_WHITE_MAGENTA_UL='\033[4;45;37m' # WHITE on MAGENTA (underlined)
C_WHITE_MAGENTA_DM='\033[2;45;37m' # WHITE on MAGENTA (dimmed)
C_WHITE_MAGENTA_BD='\033[1;45;37m' # WHITE on MAGENTA (bold/bright)
C_WHITE_MAGENTA='\033[0;45;37m' # WHITE on MAGENTA (normal)

C_BLACK_MAGENTA_HD='\033[8;45;30m' # BLACK on MAGENTA (hidden)
C_BLACK_MAGENTA_RV='\033[7;45;30m' # BLACK on MAGENTA (reversed)
C_BLACK_MAGENTA_BL='\033[5;45;30m' # BLACK on MAGENTA (blinking)
C_BLACK_MAGENTA_UL='\033[4;45;30m' # BLACK on MAGENTA (underlined)
C_BLACK_MAGENTA_DM='\033[2;45;30m' # BLACK on MAGENTA (dimmed)
C_BLACK_MAGENTA_BD='\033[1;45;30m' # BLACK on MAGENTA (bold/bright)
C_BLACK_MAGENTA='\033[0;45;30m' # BLACK on MAGENTA (normal)

C_RED_MAGENTA_HD='\033[8;45;31m' # RED on MAGENTA (hidden)
C_RED_MAGENTA_RV='\033[7;45;31m' # RED on MAGENTA (reversed)
C_RED_MAGENTA_BL='\033[5;45;31m' # RED on MAGENTA (blinking)
C_RED_MAGENTA_UL='\033[4;45;31m' # RED on MAGENTA (underlined)
C_RED_MAGENTA_DM='\033[2;45;31m' # RED on MAGENTA (dimmed)
C_RED_MAGENTA_BD='\033[1;45;31m' # RED on MAGENTA (bold/bright)
C_RED_MAGENTA='\033[0;45;31m' # RED on MAGENTA (normal)

C_GREEN_MAGENTA_HD='\033[8;45;32m' # GREEN on MAGENTA (hidden)
C_GREEN_MAGENTA_RV='\033[7;45;32m' # GREEN on MAGENTA (reversed)
C_GREEN_MAGENTA_BL='\033[5;45;32m' # GREEN on MAGENTA (blinking)
C_GREEN_MAGENTA_UL='\033[4;45;32m' # GREEN on MAGENTA (underlined)
C_GREEN_MAGENTA_DM='\033[2;45;32m' # GREEN on MAGENTA (dimmed)
C_GREEN_MAGENTA_BD='\033[1;45;32m' # GREEN on MAGENTA (bold/bright)
C_GREEN_MAGENTA='\033[0;45;32m' # GREEN on MAGENTA (normal)

C_YELLOW_MAGENTA_HD='\033[8;45;33m' # YELLOW on MAGENTA (hidden)
C_YELLOW_MAGENTA_RV='\033[7;45;33m' # YELLOW on MAGENTA (reversed)
C_YELLOW_MAGENTA_BL='\033[5;45;33m' # YELLOW on MAGENTA (blinking)
C_YELLOW_MAGENTA_UL='\033[4;45;33m' # YELLOW on MAGENTA (underlined)
C_YELLOW_MAGENTA_DM='\033[2;45;33m' # YELLOW on MAGENTA (dimmed)
C_YELLOW_MAGENTA_BD='\033[1;45;33m' # YELLOW on MAGENTA (bold/bright)
C_YELLOW_MAGENTA='\033[0;45;33m' # YELLOW on MAGENTA (normal)

C_DEFAULT_MAGENTA_HD='\033[8;45;39m' # DEFAULT on MAGENTA (hidden)
C_DEFAULT_MAGENTA_RV='\033[7;45;39m' # DEFAULT on MAGENTA (reversed)
C_DEFAULT_MAGENTA_BL='\033[5;45;39m' # DEFAULT on MAGENTA (blinking)
C_DEFAULT_MAGENTA_UL='\033[4;45;39m' # DEFAULT on MAGENTA (underlined)
C_DEFAULT_MAGENTA_DM='\033[2;45;39m' # DEFAULT on MAGENTA (dimmed)
C_DEFAULT_MAGENTA_BD='\033[1;45;39m' # DEFAULT on MAGENTA (bold/bright)
C_DEFAULT_MAGENTA='\033[0;45;39m' # DEFAULT on MAGENTA (normal)

C_BLUE_CYAN_HD='\033[8;46;34m' # BLUE on CYAN (hidden)
C_BLUE_CYAN_RV='\033[7;46;34m' # BLUE on CYAN (reversed)
C_BLUE_CYAN_BL='\033[5;46;34m' # BLUE on CYAN (blinking)
C_BLUE_CYAN_UL='\033[4;46;34m' # BLUE on CYAN (underlined)
C_BLUE_CYAN_DM='\033[2;46;34m' # BLUE on CYAN (dimmed)
C_BLUE_CYAN_BD='\033[1;46;34m' # BLUE on CYAN (bold/bright)
C_BLUE_CYAN='\033[0;46;34m' # BLUE on CYAN (normal)

C_MAGENTA_CYAN_HD='\033[8;46;35m' # MAGENTA on CYAN (hidden)
C_MAGENTA_CYAN_RV='\033[7;46;35m' # MAGENTA on CYAN (reversed)
C_MAGENTA_CYAN_BL='\033[5;46;35m' # MAGENTA on CYAN (blinking)
C_MAGENTA_CYAN_UL='\033[4;46;35m' # MAGENTA on CYAN (underlined)
C_MAGENTA_CYAN_DM='\033[2;46;35m' # MAGENTA on CYAN (dimmed)
C_MAGENTA_CYAN_BD='\033[1;46;35m' # MAGENTA on CYAN (bold/bright)
C_MAGENTA_CYAN='\033[0;46;35m' # MAGENTA on CYAN (normal)


C_WHITE_CYAN_HD='\033[8;46;37m' # WHITE on CYAN (hidden)
C_WHITE_CYAN_RV='\033[7;46;37m' # WHITE on CYAN (reversed)
C_WHITE_CYAN_BL='\033[5;46;37m' # WHITE on CYAN (blinking)
C_WHITE_CYAN_UL='\033[4;46;37m' # WHITE on CYAN (underlined)
C_WHITE_CYAN_DM='\033[2;46;37m' # WHITE on CYAN (dimmed)
C_WHITE_CYAN_BD='\033[1;46;37m' # WHITE on CYAN (bold/bright)
C_WHITE_CYAN='\033[0;46;37m' # WHITE on CYAN (normal)

C_BLACK_CYAN_HD='\033[8;46;30m' # BLACK on CYAN (hidden)
C_BLACK_CYAN_RV='\033[7;46;30m' # BLACK on CYAN (reversed)
C_BLACK_CYAN_BL='\033[5;46;30m' # BLACK on CYAN (blinking)
C_BLACK_CYAN_UL='\033[4;46;30m' # BLACK on CYAN (underlined)
C_BLACK_CYAN_DM='\033[2;46;30m' # BLACK on CYAN (dimmed)
C_BLACK_CYAN_BD='\033[1;46;30m' # BLACK on CYAN (bold/bright)
C_BLACK_CYAN='\033[0;46;30m' # BLACK on CYAN (normal)

C_RED_CYAN_HD='\033[8;46;31m' # RED on CYAN (hidden)
C_RED_CYAN_RV='\033[7;46;31m' # RED on CYAN (reversed)
C_RED_CYAN_BL='\033[5;46;31m' # RED on CYAN (blinking)
C_RED_CYAN_UL='\033[4;46;31m' # RED on CYAN (underlined)
C_RED_CYAN_DM='\033[2;46;31m' # RED on CYAN (dimmed)
C_RED_CYAN_BD='\033[1;46;31m' # RED on CYAN (bold/bright)
C_RED_CYAN='\033[0;46;31m' # RED on CYAN (normal)

C_GREEN_CYAN_HD='\033[8;46;32m' # GREEN on CYAN (hidden)
C_GREEN_CYAN_RV='\033[7;46;32m' # GREEN on CYAN (reversed)
C_GREEN_CYAN_BL='\033[5;46;32m' # GREEN on CYAN (blinking)
C_GREEN_CYAN_UL='\033[4;46;32m' # GREEN on CYAN (underlined)
C_GREEN_CYAN_DM='\033[2;46;32m' # GREEN on CYAN (dimmed)
C_GREEN_CYAN_BD='\033[1;46;32m' # GREEN on CYAN (bold/bright)
C_GREEN_CYAN='\033[0;46;32m' # GREEN on CYAN (normal)

C_YELLOW_CYAN_HD='\033[8;46;33m' # YELLOW on CYAN (hidden)
C_YELLOW_CYAN_RV='\033[7;46;33m' # YELLOW on CYAN (reversed)
C_YELLOW_CYAN_BL='\033[5;46;33m' # YELLOW on CYAN (blinking)
C_YELLOW_CYAN_UL='\033[4;46;33m' # YELLOW on CYAN (underlined)
C_YELLOW_CYAN_DM='\033[2;46;33m' # YELLOW on CYAN (dimmed)
C_YELLOW_CYAN_BD='\033[1;46;33m' # YELLOW on CYAN (bold/bright)
C_YELLOW_CYAN='\033[0;46;33m' # YELLOW on CYAN (normal)

C_DEFAULT_CYAN_HD='\033[8;46;39m' # DEFAULT on CYAN (hidden)
C_DEFAULT_CYAN_RV='\033[7;46;39m' # DEFAULT on CYAN (reversed)
C_DEFAULT_CYAN_BL='\033[5;46;39m' # DEFAULT on CYAN (blinking)
C_DEFAULT_CYAN_UL='\033[4;46;39m' # DEFAULT on CYAN (underlined)
C_DEFAULT_CYAN_DM='\033[2;46;39m' # DEFAULT on CYAN (dimmed)
C_DEFAULT_CYAN_BD='\033[1;46;39m' # DEFAULT on CYAN (bold/bright)
C_DEFAULT_CYAN='\033[0;46;39m' # DEFAULT on CYAN (normal)

C_BLUE_WHITE_HD='\033[8;47;34m' # BLUE on WHITE (hidden)
C_BLUE_WHITE_RV='\033[7;47;34m' # BLUE on WHITE (reversed)
C_BLUE_WHITE_BL='\033[5;47;34m' # BLUE on WHITE (blinking)
C_BLUE_WHITE_UL='\033[4;47;34m' # BLUE on WHITE (underlined)
C_BLUE_WHITE_DM='\033[2;47;34m' # BLUE on WHITE (dimmed)
C_BLUE_WHITE_BD='\033[1;47;34m' # BLUE on WHITE (bold/bright)
C_BLUE_WHITE='\033[0;47;34m' # BLUE on WHITE (normal)

C_MAGENTA_WHITE_HD='\033[8;47;35m' # MAGENTA on WHITE (hidden)
C_MAGENTA_WHITE_RV='\033[7;47;35m' # MAGENTA on WHITE (reversed)
C_MAGENTA_WHITE_BL='\033[5;47;35m' # MAGENTA on WHITE (blinking)
C_MAGENTA_WHITE_UL='\033[4;47;35m' # MAGENTA on WHITE (underlined)
C_MAGENTA_WHITE_DM='\033[2;47;35m' # MAGENTA on WHITE (dimmed)
C_MAGENTA_WHITE_BD='\033[1;47;35m' # MAGENTA on WHITE (bold/bright)
C_MAGENTA_WHITE='\033[0;47;35m' # MAGENTA on WHITE (normal)

C_CYAN_WHITE_HD='\033[8;47;36m' # CYAN on WHITE (hidden)
C_CYAN_WHITE_RV='\033[7;47;36m' # CYAN on WHITE (reversed)
C_CYAN_WHITE_BL='\033[5;47;36m' # CYAN on WHITE (blinking)
C_CYAN_WHITE_UL='\033[4;47;36m' # CYAN on WHITE (underlined)
C_CYAN_WHITE_DM='\033[2;47;36m' # CYAN on WHITE (dimmed)
C_CYAN_WHITE_BD='\033[1;47;36m' # CYAN on WHITE (bold/bright)
C_CYAN_WHITE='\033[0;47;36m' # CYAN on WHITE (normal)


C_BLACK_WHITE_HD='\033[8;47;30m' # BLACK on WHITE (hidden)
C_BLACK_WHITE_RV='\033[7;47;30m' # BLACK on WHITE (reversed)
C_BLACK_WHITE_BL='\033[5;47;30m' # BLACK on WHITE (blinking)
C_BLACK_WHITE_UL='\033[4;47;30m' # BLACK on WHITE (underlined)
C_BLACK_WHITE_DM='\033[2;47;30m' # BLACK on WHITE (dimmed)
C_BLACK_WHITE_BD='\033[1;47;30m' # BLACK on WHITE (bold/bright)
C_BLACK_WHITE='\033[0;47;30m' # BLACK on WHITE (normal)

C_RED_WHITE_HD='\033[8;47;31m' # RED on WHITE (hidden)
C_RED_WHITE_RV='\033[7;47;31m' # RED on WHITE (reversed)
C_RED_WHITE_BL='\033[5;47;31m' # RED on WHITE (blinking)
C_RED_WHITE_UL='\033[4;47;31m' # RED on WHITE (underlined)
C_RED_WHITE_DM='\033[2;47;31m' # RED on WHITE (dimmed)
C_RED_WHITE_BD='\033[1;47;31m' # RED on WHITE (bold/bright)
C_RED_WHITE='\033[0;47;31m' # RED on WHITE (normal)

C_GREEN_WHITE_HD='\033[8;47;32m' # GREEN on WHITE (hidden)
C_GREEN_WHITE_RV='\033[7;47;32m' # GREEN on WHITE (reversed)
C_GREEN_WHITE_BL='\033[5;47;32m' # GREEN on WHITE (blinking)
C_GREEN_WHITE_UL='\033[4;47;32m' # GREEN on WHITE (underlined)
C_GREEN_WHITE_DM='\033[2;47;32m' # GREEN on WHITE (dimmed)
C_GREEN_WHITE_BD='\033[1;47;32m' # GREEN on WHITE (bold/bright)
C_GREEN_WHITE='\033[0;47;32m' # GREEN on WHITE (normal)

C_YELLOW_WHITE_HD='\033[8;47;33m' # YELLOW on WHITE (hidden)
C_YELLOW_WHITE_RV='\033[7;47;33m' # YELLOW on WHITE (reversed)
C_YELLOW_WHITE_BL='\033[5;47;33m' # YELLOW on WHITE (blinking)
C_YELLOW_WHITE_UL='\033[4;47;33m' # YELLOW on WHITE (underlined)
C_YELLOW_WHITE_DM='\033[2;47;33m' # YELLOW on WHITE (dimmed)
C_YELLOW_WHITE_BD='\033[1;47;33m' # YELLOW on WHITE (bold/bright)
C_YELLOW_WHITE='\033[0;47;33m' # YELLOW on WHITE (normal)

C_DEFAULT_WHITE_HD='\033[8;47;39m' # DEFAULT on WHITE (hidden)
C_DEFAULT_WHITE_RV='\033[7;47;39m' # DEFAULT on WHITE (reversed)
C_DEFAULT_WHITE_BL='\033[5;47;39m' # DEFAULT on WHITE (blinking)
C_DEFAULT_WHITE_UL='\033[4;47;39m' # DEFAULT on WHITE (underlined)
C_DEFAULT_WHITE_DM='\033[2;47;39m' # DEFAULT on WHITE (dimmed)
C_DEFAULT_WHITE_BD='\033[1;47;39m' # DEFAULT on WHITE (bold/bright)
C_DEFAULT_WHITE='\033[0;47;39m' # DEFAULT on WHITE (normal)

C_BLUE_BLACK_HD='\033[8;40;34m' # BLUE on BLACK (hidden)
C_BLUE_BLACK_RV='\033[7;40;34m' # BLUE on BLACK (reversed)
C_BLUE_BLACK_BL='\033[5;40;34m' # BLUE on BLACK (blinking)
C_BLUE_BLACK_UL='\033[4;40;34m' # BLUE on BLACK (underlined)
C_BLUE_BLACK_DM='\033[2;40;34m' # BLUE on BLACK (dimmed)
C_BLUE_BLACK_BD='\033[1;40;34m' # BLUE on BLACK (bold/bright)
C_BLUE_BLACK='\033[0;40;34m' # BLUE on BLACK (normal)

C_MAGENTA_BLACK_HD='\033[8;40;35m' # MAGENTA on BLACK (hidden)
C_MAGENTA_BLACK_RV='\033[7;40;35m' # MAGENTA on BLACK (reversed)
C_MAGENTA_BLACK_BL='\033[5;40;35m' # MAGENTA on BLACK (blinking)
C_MAGENTA_BLACK_UL='\033[4;40;35m' # MAGENTA on BLACK (underlined)
C_MAGENTA_BLACK_DM='\033[2;40;35m' # MAGENTA on BLACK (dimmed)
C_MAGENTA_BLACK_BD='\033[1;40;35m' # MAGENTA on BLACK (bold/bright)
C_MAGENTA_BLACK='\033[0;40;35m' # MAGENTA on BLACK (normal)

C_CYAN_BLACK_HD='\033[8;40;36m' # CYAN on BLACK (hidden)
C_CYAN_BLACK_RV='\033[7;40;36m' # CYAN on BLACK (reversed)
C_CYAN_BLACK_BL='\033[5;40;36m' # CYAN on BLACK (blinking)
C_CYAN_BLACK_UL='\033[4;40;36m' # CYAN on BLACK (underlined)
C_CYAN_BLACK_DM='\033[2;40;36m' # CYAN on BLACK (dimmed)
C_CYAN_BLACK_BD='\033[1;40;36m' # CYAN on BLACK (bold/bright)
C_CYAN_BLACK='\033[0;40;36m' # CYAN on BLACK (normal)

C_WHITE_BLACK_HD='\033[8;40;37m' # WHITE on BLACK (hidden)
C_WHITE_BLACK_RV='\033[7;40;37m' # WHITE on BLACK (reversed)
C_WHITE_BLACK_BL='\033[5;40;37m' # WHITE on BLACK (blinking)
C_WHITE_BLACK_UL='\033[4;40;37m' # WHITE on BLACK (underlined)
C_WHITE_BLACK_DM='\033[2;40;37m' # WHITE on BLACK (dimmed)
C_WHITE_BLACK_BD='\033[1;40;37m' # WHITE on BLACK (bold/bright)
C_WHITE_BLACK='\033[0;40;37m' # WHITE on BLACK (normal)


C_RED_BLACK_HD='\033[8;40;31m' # RED on BLACK (hidden)
C_RED_BLACK_RV='\033[7;40;31m' # RED on BLACK (reversed)
C_RED_BLACK_BL='\033[5;40;31m' # RED on BLACK (blinking)
C_RED_BLACK_UL='\033[4;40;31m' # RED on BLACK (underlined)
C_RED_BLACK_DM='\033[2;40;31m' # RED on BLACK (dimmed)
C_RED_BLACK_BD='\033[1;40;31m' # RED on BLACK (bold/bright)
C_RED_BLACK='\033[0;40;31m' # RED on BLACK (normal)

C_GREEN_BLACK_HD='\033[8;40;32m' # GREEN on BLACK (hidden)
C_GREEN_BLACK_RV='\033[7;40;32m' # GREEN on BLACK (reversed)
C_GREEN_BLACK_BL='\033[5;40;32m' # GREEN on BLACK (blinking)
C_GREEN_BLACK_UL='\033[4;40;32m' # GREEN on BLACK (underlined)
C_GREEN_BLACK_DM='\033[2;40;32m' # GREEN on BLACK (dimmed)
C_GREEN_BLACK_BD='\033[1;40;32m' # GREEN on BLACK (bold/bright)
C_GREEN_BLACK='\033[0;40;32m' # GREEN on BLACK (normal)

C_YELLOW_BLACK_HD='\033[8;40;33m' # YELLOW on BLACK (hidden)
C_YELLOW_BLACK_RV='\033[7;40;33m' # YELLOW on BLACK (reversed)
C_YELLOW_BLACK_BL='\033[5;40;33m' # YELLOW on BLACK (blinking)
C_YELLOW_BLACK_UL='\033[4;40;33m' # YELLOW on BLACK (underlined)
C_YELLOW_BLACK_DM='\033[2;40;33m' # YELLOW on BLACK (dimmed)
C_YELLOW_BLACK_BD='\033[1;40;33m' # YELLOW on BLACK (bold/bright)
C_YELLOW_BLACK='\033[0;40;33m' # YELLOW on BLACK (normal)

C_DEFAULT_BLACK_HD='\033[8;40;39m' # DEFAULT on BLACK (hidden)
C_DEFAULT_BLACK_RV='\033[7;40;39m' # DEFAULT on BLACK (reversed)
C_DEFAULT_BLACK_BL='\033[5;40;39m' # DEFAULT on BLACK (blinking)
C_DEFAULT_BLACK_UL='\033[4;40;39m' # DEFAULT on BLACK (underlined)
C_DEFAULT_BLACK_DM='\033[2;40;39m' # DEFAULT on BLACK (dimmed)
C_DEFAULT_BLACK_BD='\033[1;40;39m' # DEFAULT on BLACK (bold/bright)
C_DEFAULT_BLACK='\033[0;40;39m' # DEFAULT on BLACK (normal)

C_BLUE_RED_HD='\033[8;41;34m' # BLUE on RED (hidden)
C_BLUE_RED_RV='\033[7;41;34m' # BLUE on RED (reversed)
C_BLUE_RED_BL='\033[5;41;34m' # BLUE on RED (blinking)
C_BLUE_RED_UL='\033[4;41;34m' # BLUE on RED (underlined)
C_BLUE_RED_DM='\033[2;41;34m' # BLUE on RED (dimmed)
C_BLUE_RED_BD='\033[1;41;34m' # BLUE on RED (bold/bright)
C_BLUE_RED='\033[0;41;34m' # BLUE on RED (normal)

C_MAGENTA_RED_HD='\033[8;41;35m' # MAGENTA on RED (hidden)
C_MAGENTA_RED_RV='\033[7;41;35m' # MAGENTA on RED (reversed)
C_MAGENTA_RED_BL='\033[5;41;35m' # MAGENTA on RED (blinking)
C_MAGENTA_RED_UL='\033[4;41;35m' # MAGENTA on RED (underlined)
C_MAGENTA_RED_DM='\033[2;41;35m' # MAGENTA on RED (dimmed)
C_MAGENTA_RED_BD='\033[1;41;35m' # MAGENTA on RED (bold/bright)
C_MAGENTA_RED='\033[0;41;35m' # MAGENTA on RED (normal)

C_CYAN_RED_HD='\033[8;41;36m' # CYAN on RED (hidden)
C_CYAN_RED_RV='\033[7;41;36m' # CYAN on RED (reversed)
C_CYAN_RED_BL='\033[5;41;36m' # CYAN on RED (blinking)
C_CYAN_RED_UL='\033[4;41;36m' # CYAN on RED (underlined)
C_CYAN_RED_DM='\033[2;41;36m' # CYAN on RED (dimmed)
C_CYAN_RED_BD='\033[1;41;36m' # CYAN on RED (bold/bright)
C_CYAN_RED='\033[0;41;36m' # CYAN on RED (normal)

C_WHITE_RED_HD='\033[8;41;37m' # WHITE on RED (hidden)
C_WHITE_RED_RV='\033[7;41;37m' # WHITE on RED (reversed)
C_WHITE_RED_BL='\033[5;41;37m' # WHITE on RED (blinking)
C_WHITE_RED_UL='\033[4;41;37m' # WHITE on RED (underlined)
C_WHITE_RED_DM='\033[2;41;37m' # WHITE on RED (dimmed)
C_WHITE_RED_BD='\033[1;41;37m' # WHITE on RED (bold/bright)
C_WHITE_RED='\033[0;41;37m' # WHITE on RED (normal)

C_BLACK_RED_HD='\033[8;41;30m' # BLACK on RED (hidden)
C_BLACK_RED_RV='\033[7;41;30m' # BLACK on RED (reversed)
C_BLACK_RED_BL='\033[5;41;30m' # BLACK on RED (blinking)
C_BLACK_RED_UL='\033[4;41;30m' # BLACK on RED (underlined)
C_BLACK_RED_DM='\033[2;41;30m' # BLACK on RED (dimmed)
C_BLACK_RED_BD='\033[1;41;30m' # BLACK on RED (bold/bright)
C_BLACK_RED='\033[0;41;30m' # BLACK on RED (normal)


C_GREEN_RED_HD='\033[8;41;32m' # GREEN on RED (hidden)
C_GREEN_RED_RV='\033[7;41;32m' # GREEN on RED (reversed)
C_GREEN_RED_BL='\033[5;41;32m' # GREEN on RED (blinking)
C_GREEN_RED_UL='\033[4;41;32m' # GREEN on RED (underlined)
C_GREEN_RED_DM='\033[2;41;32m' # GREEN on RED (dimmed)
C_GREEN_RED_BD='\033[1;41;32m' # GREEN on RED (bold/bright)
C_GREEN_RED='\033[0;41;32m' # GREEN on RED (normal)

C_YELLOW_RED_HD='\033[8;41;33m' # YELLOW on RED (hidden)
C_YELLOW_RED_RV='\033[7;41;33m' # YELLOW on RED (reversed)
C_YELLOW_RED_BL='\033[5;41;33m' # YELLOW on RED (blinking)
C_YELLOW_RED_UL='\033[4;41;33m' # YELLOW on RED (underlined)
C_YELLOW_RED_DM='\033[2;41;33m' # YELLOW on RED (dimmed)
C_YELLOW_RED_BD='\033[1;41;33m' # YELLOW on RED (bold/bright)
C_YELLOW_RED='\033[0;41;33m' # YELLOW on RED (normal)

C_DEFAULT_RED_HD='\033[8;41;39m' # DEFAULT on RED (hidden)
C_DEFAULT_RED_RV='\033[7;41;39m' # DEFAULT on RED (reversed)
C_DEFAULT_RED_BL='\033[5;41;39m' # DEFAULT on RED (blinking)
C_DEFAULT_RED_UL='\033[4;41;39m' # DEFAULT on RED (underlined)
C_DEFAULT_RED_DM='\033[2;41;39m' # DEFAULT on RED (dimmed)
C_DEFAULT_RED_BD='\033[1;41;39m' # DEFAULT on RED (bold/bright)
C_DEFAULT_RED='\033[0;41;39m' # DEFAULT on RED (normal)

C_BLUE_GREEN_HD='\033[8;42;34m' # BLUE on GREEN (hidden)
C_BLUE_GREEN_RV='\033[7;42;34m' # BLUE on GREEN (reversed)
C_BLUE_GREEN_BL='\033[5;42;34m' # BLUE on GREEN (blinking)
C_BLUE_GREEN_UL='\033[4;42;34m' # BLUE on GREEN (underlined)
C_BLUE_GREEN_DM='\033[2;42;34m' # BLUE on GREEN (dimmed)
C_BLUE_GREEN_BD='\033[1;42;34m' # BLUE on GREEN (bold/bright)
C_BLUE_GREEN='\033[0;42;34m' # BLUE on GREEN (normal)

C_MAGENTA_GREEN_HD='\033[8;42;35m' # MAGENTA on GREEN (hidden)
C_MAGENTA_GREEN_RV='\033[7;42;35m' # MAGENTA on GREEN (reversed)
C_MAGENTA_GREEN_BL='\033[5;42;35m' # MAGENTA on GREEN (blinking)
C_MAGENTA_GREEN_UL='\033[4;42;35m' # MAGENTA on GREEN (underlined)
C_MAGENTA_GREEN_DM='\033[2;42;35m' # MAGENTA on GREEN (dimmed)
C_MAGENTA_GREEN_BD='\033[1;42;35m' # MAGENTA on GREEN (bold/bright)
C_MAGENTA_GREEN='\033[0;42;35m' # MAGENTA on GREEN (normal)

C_CYAN_GREEN_HD='\033[8;42;36m' # CYAN on GREEN (hidden)
C_CYAN_GREEN_RV='\033[7;42;36m' # CYAN on GREEN (reversed)
C_CYAN_GREEN_BL='\033[5;42;36m' # CYAN on GREEN (blinking)
C_CYAN_GREEN_UL='\033[4;42;36m' # CYAN on GREEN (underlined)
C_CYAN_GREEN_DM='\033[2;42;36m' # CYAN on GREEN (dimmed)
C_CYAN_GREEN_BD='\033[1;42;36m' # CYAN on GREEN (bold/bright)
C_CYAN_GREEN='\033[0;42;36m' # CYAN on GREEN (normal)

C_WHITE_GREEN_HD='\033[8;42;37m' # WHITE on GREEN (hidden)
C_WHITE_GREEN_RV='\033[7;42;37m' # WHITE on GREEN (reversed)
C_WHITE_GREEN_BL='\033[5;42;37m' # WHITE on GREEN (blinking)
C_WHITE_GREEN_UL='\033[4;42;37m' # WHITE on GREEN (underlined)
C_WHITE_GREEN_DM='\033[2;42;37m' # WHITE on GREEN (dimmed)
C_WHITE_GREEN_BD='\033[1;42;37m' # WHITE on GREEN (bold/bright)
C_WHITE_GREEN='\033[0;42;37m' # WHITE on GREEN (normal)

C_BLACK_GREEN_HD='\033[8;42;30m' # BLACK on GREEN (hidden)
C_BLACK_GREEN_RV='\033[7;42;30m' # BLACK on GREEN (reversed)
C_BLACK_GREEN_BL='\033[5;42;30m' # BLACK on GREEN (blinking)
C_BLACK_GREEN_UL='\033[4;42;30m' # BLACK on GREEN (underlined)
C_BLACK_GREEN_DM='\033[2;42;30m' # BLACK on GREEN (dimmed)
C_BLACK_GREEN_BD='\033[1;42;30m' # BLACK on GREEN (bold/bright)
C_BLACK_GREEN='\033[0;42;30m' # BLACK on GREEN (normal)

C_RED_GREEN_HD='\033[8;42;31m' # RED on GREEN (hidden)
C_RED_GREEN_RV='\033[7;42;31m' # RED on GREEN (reversed)
C_RED_GREEN_BL='\033[5;42;31m' # RED on GREEN (blinking)
C_RED_GREEN_UL='\033[4;42;31m' # RED on GREEN (underlined)
C_RED_GREEN_DM='\033[2;42;31m' # RED on GREEN (dimmed)
C_RED_GREEN_BD='\033[1;42;31m' # RED on GREEN (bold/bright)
C_RED_GREEN='\033[0;42;31m' # RED on GREEN (normal)


C_YELLOW_GREEN_HD='\033[8;42;33m' # YELLOW on GREEN (hidden)
C_YELLOW_GREEN_RV='\033[7;42;33m' # YELLOW on GREEN (reversed)
C_YELLOW_GREEN_BL='\033[5;42;33m' # YELLOW on GREEN (blinking)
C_YELLOW_GREEN_UL='\033[4;42;33m' # YELLOW on GREEN (underlined)
C_YELLOW_GREEN_DM='\033[2;42;33m' # YELLOW on GREEN (dimmed)
C_YELLOW_GREEN_BD='\033[1;42;33m' # YELLOW on GREEN (bold/bright)
C_YELLOW_GREEN='\033[0;42;33m' # YELLOW on GREEN (normal)

C_DEFAULT_GREEN_HD='\033[8;42;39m' # DEFAULT on GREEN (hidden)
C_DEFAULT_GREEN_RV='\033[7;42;39m' # DEFAULT on GREEN (reversed)
C_DEFAULT_GREEN_BL='\033[5;42;39m' # DEFAULT on GREEN (blinking)
C_DEFAULT_GREEN_UL='\033[4;42;39m' # DEFAULT on GREEN (underlined)
C_DEFAULT_GREEN_DM='\033[2;42;39m' # DEFAULT on GREEN (dimmed)
C_DEFAULT_GREEN_BD='\033[1;42;39m' # DEFAULT on GREEN (bold/bright)
C_DEFAULT_GREEN='\033[0;42;39m' # DEFAULT on GREEN (normal)

C_BLUE_YELLOW_HD='\033[8;43;34m' # BLUE on YELLOW (hidden)
C_BLUE_YELLOW_RV='\033[7;43;34m' # BLUE on YELLOW (reversed)
C_BLUE_YELLOW_BL='\033[5;43;34m' # BLUE on YELLOW (blinking)
C_BLUE_YELLOW_UL='\033[4;43;34m' # BLUE on YELLOW (underlined)
C_BLUE_YELLOW_DM='\033[2;43;34m' # BLUE on YELLOW (dimmed)
C_BLUE_YELLOW_BD='\033[1;43;34m' # BLUE on YELLOW (bold/bright)
C_BLUE_YELLOW='\033[0;43;34m' # BLUE on YELLOW (normal)

C_MAGENTA_YELLOW_HD='\033[8;43;35m' # MAGENTA on YELLOW (hidden)
C_MAGENTA_YELLOW_RV='\033[7;43;35m' # MAGENTA on YELLOW (reversed)
C_MAGENTA_YELLOW_BL='\033[5;43;35m' # MAGENTA on YELLOW (blinking)
C_MAGENTA_YELLOW_UL='\033[4;43;35m' # MAGENTA on YELLOW (underlined)
C_MAGENTA_YELLOW_DM='\033[2;43;35m' # MAGENTA on YELLOW (dimmed)
C_MAGENTA_YELLOW_BD='\033[1;43;35m' # MAGENTA on YELLOW (bold/bright)
C_MAGENTA_YELLOW='\033[0;43;35m' # MAGENTA on YELLOW (normal)

C_CYAN_YELLOW_HD='\033[8;43;36m' # CYAN on YELLOW (hidden)
C_CYAN_YELLOW_RV='\033[7;43;36m' # CYAN on YELLOW (reversed)
C_CYAN_YELLOW_BL='\033[5;43;36m' # CYAN on YELLOW (blinking)
C_CYAN_YELLOW_UL='\033[4;43;36m' # CYAN on YELLOW (underlined)
C_CYAN_YELLOW_DM='\033[2;43;36m' # CYAN on YELLOW (dimmed)
C_CYAN_YELLOW_BD='\033[1;43;36m' # CYAN on YELLOW (bold/bright)
C_CYAN_YELLOW='\033[0;43;36m' # CYAN on YELLOW (normal)

C_WHITE_YELLOW_HD='\033[8;43;37m' # WHITE on YELLOW (hidden)
C_WHITE_YELLOW_RV='\033[7;43;37m' # WHITE on YELLOW (reversed)
C_WHITE_YELLOW_BL='\033[5;43;37m' # WHITE on YELLOW (blinking)
C_WHITE_YELLOW_UL='\033[4;43;37m' # WHITE on YELLOW (underlined)
C_WHITE_YELLOW_DM='\033[2;43;37m' # WHITE on YELLOW (dimmed)
C_WHITE_YELLOW_BD='\033[1;43;37m' # WHITE on YELLOW (bold/bright)
C_WHITE_YELLOW='\033[0;43;37m' # WHITE on YELLOW (normal)

C_BLACK_YELLOW_HD='\033[8;43;30m' # BLACK on YELLOW (hidden)
C_BLACK_YELLOW_RV='\033[7;43;30m' # BLACK on YELLOW (reversed)
C_BLACK_YELLOW_BL='\033[5;43;30m' # BLACK on YELLOW (blinking)
C_BLACK_YELLOW_UL='\033[4;43;30m' # BLACK on YELLOW (underlined)
C_BLACK_YELLOW_DM='\033[2;43;30m' # BLACK on YELLOW (dimmed)
C_BLACK_YELLOW_BD='\033[1;43;30m' # BLACK on YELLOW (bold/bright)
C_BLACK_YELLOW='\033[0;43;30m' # BLACK on YELLOW (normal)

C_RED_YELLOW_HD='\033[8;43;31m' # RED on YELLOW (hidden)
C_RED_YELLOW_RV='\033[7;43;31m' # RED on YELLOW (reversed)
C_RED_YELLOW_BL='\033[5;43;31m' # RED on YELLOW (blinking)
C_RED_YELLOW_UL='\033[4;43;31m' # RED on YELLOW (underlined)
C_RED_YELLOW_DM='\033[2;43;31m' # RED on YELLOW (dimmed)
C_RED_YELLOW_BD='\033[1;43;31m' # RED on YELLOW (bold/bright)
C_RED_YELLOW='\033[0;43;31m' # RED on YELLOW (normal)

C_GREEN_YELLOW_HD='\033[8;43;32m' # GREEN on YELLOW (hidden)
C_GREEN_YELLOW_RV='\033[7;43;32m' # GREEN on YELLOW (reversed)
C_GREEN_YELLOW_BL='\033[5;43;32m' # GREEN on YELLOW (blinking)
C_GREEN_YELLOW_UL='\033[4;43;32m' # GREEN on YELLOW (underlined)
C_GREEN_YELLOW_DM='\033[2;43;32m' # GREEN on YELLOW (dimmed)
C_GREEN_YELLOW_BD='\033[1;43;32m' # GREEN on YELLOW (bold/bright)
C_GREEN_YELLOW='\033[0;43;32m' # GREEN on YELLOW (normal)


C_DEFAULT_YELLOW_HD='\033[8;43;39m' # DEFAULT on YELLOW (hidden)
C_DEFAULT_YELLOW_RV='\033[7;43;39m' # DEFAULT on YELLOW (reversed)
C_DEFAULT_YELLOW_BL='\033[5;43;39m' # DEFAULT on YELLOW (blinking)
C_DEFAULT_YELLOW_UL='\033[4;43;39m' # DEFAULT on YELLOW (underlined)
C_DEFAULT_YELLOW_DM='\033[2;43;39m' # DEFAULT on YELLOW (dimmed)
C_DEFAULT_YELLOW_BD='\033[1;43;39m' # DEFAULT on YELLOW (bold/bright)
C_DEFAULT_YELLOW='\033[0;43;39m' # DEFAULT on YELLOW (normal)

C_BLUE_HD='\033[8;49;34m' # BLUE on DEFAULT (hidden)
C_BLUE_RV='\033[7;49;34m' # BLUE on DEFAULT (reversed)
C_BLUE_BL='\033[5;49;34m' # BLUE on DEFAULT (blinking)
C_BLUE_UL='\033[4;49;34m' # BLUE on DEFAULT (underlined)
C_BLUE_DM='\033[2;49;34m' # BLUE on DEFAULT (dimmed)
C_BLUE_BD='\033[1;49;34m' # BLUE on DEFAULT (bold/bright)

C_MAGENTA_HD='\033[8;49;35m' # MAGENTA on DEFAULT (hidden)
C_MAGENTA_RV='\033[7;49;35m' # MAGENTA on DEFAULT (reversed)
C_MAGENTA_BL='\033[5;49;35m' # MAGENTA on DEFAULT (blinking)
C_MAGENTA_UL='\033[4;49;35m' # MAGENTA on DEFAULT (underlined)
C_MAGENTA_DM='\033[2;49;35m' # MAGENTA on DEFAULT (dimmed)
C_MAGENTA_BD='\033[1;49;35m' # MAGENTA on DEFAULT (bold/bright)

C_CYAN_HD='\033[8;49;36m' # CYAN on DEFAULT (hidden)
C_CYAN_RV='\033[7;49;36m' # CYAN on DEFAULT (reversed)
C_CYAN_BL='\033[5;49;36m' # CYAN on DEFAULT (blinking)
C_CYAN_UL='\033[4;49;36m' # CYAN on DEFAULT (underlined)
C_CYAN_DM='\033[2;49;36m' # CYAN on DEFAULT (dimmed)
C_CYAN_BD='\033[1;49;36m' # CYAN on DEFAULT (bold/bright)

C_WHITE_HD='\033[8;49;37m' # WHITE on DEFAULT (hidden)
C_WHITE_RV='\033[7;49;37m' # WHITE on DEFAULT (reversed)
C_WHITE_BL='\033[5;49;37m' # WHITE on DEFAULT (blinking)
C_WHITE_UL='\033[4;49;37m' # WHITE on DEFAULT (underlined)
C_WHITE_DM='\033[2;49;37m' # WHITE on DEFAULT (dimmed)
C_WHITE_BD='\033[1;49;37m' # WHITE on DEFAULT (bold/bright)

C_BLACK_HD='\033[8;49;30m' # BLACK on DEFAULT (hidden)
C_BLACK_RV='\033[7;49;30m' # BLACK on DEFAULT (reversed)
C_BLACK_BL='\033[5;49;30m' # BLACK on DEFAULT (blinking)
C_BLACK_UL='\033[4;49;30m' # BLACK on DEFAULT (underlined)
C_BLACK_DM='\033[2;49;30m' # BLACK on DEFAULT (dimmed)
C_BLACK_BD='\033[1;49;30m' # BLACK on DEFAULT (bold/bright)

C_RED_HD='\033[8;49;31m' # RED on DEFAULT (hidden)
C_RED_RV='\033[7;49;31m' # RED on DEFAULT (reversed)
C_RED_BL='\033[5;49;31m' # RED on DEFAULT (blinking)
C_RED_UL='\033[4;49;31m' # RED on DEFAULT (underlined)
C_RED_DM='\033[2;49;31m' # RED on DEFAULT (dimmed)
C_RED_BD='\033[1;49;31m' # RED on DEFAULT (bold/bright)

C_GREEN_HD='\033[8;49;32m' # GREEN on DEFAULT (hidden)
C_GREEN_RV='\033[7;49;32m' # GREEN on DEFAULT (reversed)
C_GREEN_BL='\033[5;49;32m' # GREEN on DEFAULT (blinking)
C_GREEN_UL='\033[4;49;32m' # GREEN on DEFAULT (underlined)
C_GREEN_DM='\033[2;49;32m' # GREEN on DEFAULT (dimmed)
C_GREEN_BD='\033[1;49;32m' # GREEN on DEFAULT (bold/bright)

C_YELLOW_HD='\033[8;49;33m' # YELLOW on DEFAULT (hidden)
C_YELLOW_RV='\033[7;49;33m' # YELLOW on DEFAULT (reversed)
C_YELLOW_BL='\033[5;49;33m' # YELLOW on DEFAULT (blinking)
C_YELLOW_UL='\033[4;49;33m' # YELLOW on DEFAULT (underlined)
C_YELLOW_DM='\033[2;49;33m' # YELLOW on DEFAULT (dimmed)
C_YELLOW_BD='\033[1;49;33m' # YELLOW on DEFAULT (bold/bright)

# Convenience aliases
C_ORANGE=$C_YELLOW
C_NC='\033[0m'
