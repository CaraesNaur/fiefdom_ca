#!/bin/bash

# Navigate to script location
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")"

source includes/common.sh

# Declare directory base names for CA chain members
CA_BASE_PATH=$(pwd)
ROOT_CA_DIR_BASE=root
INTM_CA_DIR_BASE=intm
HOSTS_DIR_BASE=hosts
CA_DIR_EXT=_ca_base

# Declare other values
CONF_FILE="openssl.cnf"
START_SERIAL=1000
START_CRL_NUMBER=1000
ROOT_CA_CERT_DAYS=7300
INTM_CA_CERT_DAYS=3650

DIST_FILES_DIR=dist_files

SUBDIR_LIST=( "certs" "crl" "csr" "newcerts" "private" )

################################################
# Establish file paths                         #
################################################
ROOT_CA_DIR="${ROOT_CA_DIR_BASE}${CA_DIR_EXT}"
ROOT_CA_PATH="${CA_BASE_PATH}/${ROOT_CA_DIR}"
ROOT_CA_DIST_CONF_FILE="${CA_BASE_PATH}/${DIST_FILES_DIR}/root_openssl.conf.dist"
ROOT_CONF_FILE="${ROOT_CA_PATH}/${CONF_FILE}"

INTM_CA_DIR="${INTM_CA_DIR_BASE}${CA_DIR_EXT}"
INTM_CA_PATH="${CA_BASE_PATH}/${INTM_CA_DIR}"
INTM_CA_DIST_CONF_FILE="${CA_BASE_PATH}/${DIST_FILES_DIR}/intermediate_openssl_conf.dist"
INTM_CONF_FILE="${INTM_CA_PATH}/${CONF_FILE}"

HOSTS_CA_PATH="${CA_BASE_PATH}/${HOSTS_DIR_BASE}"

################################################
# Check for existence of necessary paths       #
################################################
SETUP_ABORT=false

for P in ROOT_CA_PATH INTM_CA_PATH HOSTS_CA_PATH CA_CONFIG_FILE
do
	if [[ "${P}" != CA_CONFIG_FILE ]]
	then
		if [[ ! -d "${!P}" ]]
		then
			echo -e "${C_WHITE_GREEN_BD}!!!${C_GREEN} Path ${C_GREEN_BD}${!P}${C_GREEN} not found.${C_NC}"
		else
			echo -e "${C_WHITE_RED_BD}!!!${C_RED} Path ${C_RED_BD}${!P}${C_RED} exists.${C_NC}"

			SETUP_ABORT=true
		fi
	else
		if [[ ! -f "${!P}" ]]
		then
			echo -e "${C_WHITE_GREEN_BD}!!!${C_GREEN} File ${C_GREEN_BD}${!P}${C_GREEN} not found.${C_NC}"
		else
			echo -e "${C_WHITE_RED_BD}!!!${C_RED} File ${C_RED_BD}${!P}${C_RED} exists.${C_NC}"

			SETUP_ABORT=true
		fi
	fi
done

echo

if [[ "${SETUP_ABORT}" == true ]]
then
	echo -e "${C_RED}One or more resources necessary for the CA were found.${C_NC}"
	echo -e "${C_RED}If these are not needed, delete/rename them and run this script again.${C_NC}"
	echo
	echo -e "${C_WHITE_RED_BD} Aborting Certificate Authority setup. ${C_NC}"

	exit 1
else
	echo
	echo -e "${C_WHITE_GREEN_BD} Performing Certificate Authority setup... ${C_NC}"
	echo
fi

################################################
# Capture domain name for CA governance        #
################################################

echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo -e "${C_WHITE_BLUE_BD}# Certificate Authority Domain                     #${C_NC}"
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo
echo "Certificate Authority domain forms the basis of hostnames governed"
echo "by the CA.  Hostnames are constructed as:"
echo
echo -e "    ${C_MAGENTA_BD}[host name]${C_WHITE_BD}.${C_MAGENTA_BD}[domain]${C_NC}"
echo
echo -e "For convenience, the output of ${C_MAGENTA}\`hostname\`${C_NC} is provided as a default."
echo
read -p "Certificate Authority Domain (no leading/trailing dots): " -i $(hostname) -e HOST_DOMAIN_NAME

while [[ ! "${HOST_DOMAIN_NAME}" =~ ${HOST_DOMAIN_MATCH} ]]
do
	read -p "Certificate Authority Domain name must be a valid hostname: " -i "${HOST_DOMAIN_NAME}" -e HOST_DOMAIN_NAME
done

HOST_DOMAIN_NAME="${HOST_DOMAIN_NAME,,}"

echo -e "Host domain: ${C_CYAN_BD}${HOST_DOMAIN_NAME}${C_CYAN}"

# Set filenames used below
ROOT_CA_KEY_FILE="${ROOT_CA_PATH}/private/${HOST_DOMAIN_NAME}_${ROOT_CA_REFNAME}${CA_KEY_FILE_BASE}"
ROOT_CA_CERT_FILE="${ROOT_CA_PATH}/certs/${HOST_DOMAIN_NAME}_${ROOT_CA_REFNAME}${CA_CERT_FILE_BASE}"
ROOT_CA_CRL_FILE="${ROOT_CA_PATH}/crl/${HOST_DOMAIN_NAME}_${ROOT_CA_REFNAME}${CA_CRL_FILE_BASE}"

INTM_CA_KEY_FILE="${INTM_CA_PATH}/private/${HOST_DOMAIN_NAME}_${INTM_CA_REFNAME}${CA_KEY_FILE_BASE}"
INTM_CA_CSR_FILE="${INTM_CA_PATH}/csr/${HOST_DOMAIN_NAME}_${INTM_CA_REFNAME}${CA_CSR_FILE_BASE}"
INTM_CA_CERT_FILE="${INTM_CA_PATH}/certs/${HOST_DOMAIN_NAME}_${INTM_CA_REFNAME}${CA_CERT_FILE_BASE}"
INTM_CA_CHAIN_FILE="${INTM_CA_PATH}/certs/${HOST_DOMAIN_NAME}_${INTM_CA_REFNAME}${CA_CHAIN_FILE_BASE}"
INTM_CA_CRL_FILE="${ROOT_CA_PATH}/crl/${HOST_DOMAIN_NAME}_${INTM_CA_REFNAME}${CA_CRL_FILE_BASE}"

################################################
# Populate CA config file                      #
################################################
echo -e "${C_GREEN}Writing Certificate Authority config file to ${C_GREEN_BD}${CA_BASE_PATH}/${CA_CONFIG_FILE}${C_NC}"

cat <<EOT > ${CA_BASE_PATH}/${CA_CONFIG_FILE}
################################################
# Root Certificate Authority                   #
################################################
ROOT_CA_CERT_FILE=${ROOT_CA_CERT_FILE}
ROOT_CA_DIR=${ROOT_CA_DIR}
ROOT_CA_FULLNAME=${ROOT_CA_FULLNAME}
ROOT_CA_KEY_FILE=${ROOT_CA_KEY_FILE}
ROOT_CA_PATH=${ROOT_CA_PATH}
ROOT_CONF_FILE=${ROOT_CONF_FILE}

################################################
# Intermediate Certificate Authority           #
################################################
INTM_CA_CERT_FILE=${INTM_CA_CERT_FILE}
INTM_CA_DIR=${INTM_CA_DIR}
INTM_CA_CHAIN_FILE=${INTM_CA_CHAIN_FILE}
INTM_CA_FULLNAME=${INTM_CA_FULLNAME}
INTM_CA_KEY_FILE=${INTM_CA_KEY_FILE}
INTM_CA_PATH=${INTM_CA_PATH}
INTM_CONF_FILE=${INTM_CONF_FILE}

################################################
# Host Domain Values                           #
################################################
HOSTS_CA_PATH=${HOSTS_CA_PATH}
HOST_DOMAIN_NAME=${HOST_DOMAIN_NAME}
HOST_CERT_DAYS=${HOST_CERT_DAYS_DEFAULT}

################################################
# Host Domain Values                           #
################################################
HOST_DEFAULT_COUNTRY=""
HOST_DEFAULT_PROVINCE=""
HOST_DEFAULT_LOCALITY=""
HOST_DEFAULT_ORG_NAME=""
HOST_DEFAULT_ORG_UNIT_NAME=""

EOT

# End config file output

echo

################################################
# Prepare CA Chain                             #
################################################

declare -A ROOT_CA_DN_DEFAULTS=(
	["countryName"]=""
	["stateOrProvinceName"]=""
	["localityName"]=""
	["0.organizationName"]=""
	["organizationalUnitName"]=""
	["emailAddress"]=""
);

declare -A INTM_CA_DN_DEFAULTS=(
	["countryName"]=""
	["stateOrProvinceName"]=""
	["localityName"]=""
	["0.organizationName"]=""
	["organizationalUnitName"]=""
	["emailAddress"]=""
);

for CAC in root intm
do
	CAC_LABEL="${CAC^}"
	CAC_BIT="${CAC^^}"

	declare "CAC_CA_FULLNAME=${CAC_BIT}_CA_FULLNAME"
	declare "CAC_CA_REFNAME=${CAC_BIT}_CA_REFNAME"
	declare "CAC_CA_DIR=${CAC_BIT}_CA_DIR"
	declare "CAC_CA_PATH=${CAC_BIT}_CA_PATH"
	declare "CAC_CA_CONF_FILE=${CAC_BIT}_CONF_FILE"
	declare "CAC_CA_DIST_CONF_FILE=${CAC_BIT}_CA_DIST_CONF_FILE"
	declare "CAC_CA_KEY_FILE=${CAC_BIT}_CA_KEY_FILE"
	declare "CAC_CA_CERT_FILE=${CAC_BIT}_CA_CERT_FILE"
	declare "CAC_CA_CERT_DAYS=${CAC_BIT}_CA_CERT_DAYS"
	declare "CAC_CA_CRL_FILE=${CAC_BIT}_CA_CRL_FILE"

	CAC_CA_FULLNAME="${!CAC_CA_FULLNAME}"
	CAC_CA_REFNAME="${!CAC_CA_REFNAME}"
	CAC_CA_DIR="${!CAC_CA_DIR}"
	CAC_CA_PATH="${!CAC_CA_PATH}"
	CAC_CA_CONF_FILE="${!CAC_CA_CONF_FILE}"
	CAC_CA_DIST_CONF_FILE="${!CAC_CA_DIST_CONF_FILE}"
	CAC_CA_KEY_FILE="${!CAC_CA_KEY_FILE}"
	CAC_CA_CERT_FILE="${!CAC_CA_CERT_FILE}"
	CAC_CA_CERT_DAYS="${!CAC_CA_CERT_DAYS}"
	CAC_CA_CRL_FILE="${!CAC_CA_CRL_FILE}"

	if [[ "${CAC}" == root ]]
	then
		declare -n CAC_CA_DN_DEFAULTS=ROOT_CA_DN_DEFAULTS
	else
		declare -n CAC_CA_DN_DEFAULTS=INTM_CA_DN_DEFAULTS
	fi

	CAC_CA_KEY_FILE_BARE=$(basename ${CAC_CA_KEY_FILE})
	CAC_CA_CERT_FILE_BARE=$(basename ${CAC_CA_CERT_FILE})
	CAC_CA_CRL_FILE_BARE=$(basename ${CAC_CA_CRL_FILE})

	echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
	echo -e -n "${C_WHITE_BLUE_BD}"
	printf "%s%-19s%s" "# Certificate Authority Setup: " "${CAC_CA_FULLNAME}" " #"
	echo -e "${C_NC}"
	echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"

	echo -e "${C_CYAN_BD}${CAC_CA_FULLNAME}${C_NC} CA path: ${C_GREEN_BD}${CAC_CA_PATH}${C_NC}"
	echo

	if [ -d ${CAC_CA_DIR} ]
	then
		echo -e "${C_WHITE_RED_BD}!!!${C_RED} Found ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_RED} CA base directory ${C_RED_BD}${CAC_CA_DIR}${C_NC}"
		echo -e "${C_WHITE_RED_BD}!!!${C_RED} Aborting setup.${C_NC}"

		exit 1
	else
		echo -e "${C_GREEN}Creating ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_GREEN} CA base directory ${C_GREEN_BD}${CAC_CA_DIR}/${D}${C_NC}"
		mkdir ${CAC_CA_DIR}
	fi

	echo -e "${C_GREEN}Preparing ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_GREEN} CA subdirectories...${C_NC}"

	for D in "${SUBDIR_LIST[@]}"
	do
		mkdir -p ${CAC_CA_DIR}/${D}
	done

	echo -e "${C_GREEN}Creating ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_GREEN} index file at ${C_GREEN_BD}${CAC_CA_DIR}/index.txt${C_NC}"
	touch ${CAC_CA_DIR}/index.txt

	echo -e "${C_GREEN}Setting permissions of ${C_GREEN_BD}${CAC_CA_DIR}/private${C_GREEN} to ${C_WHITE_BD}700${C_GREEN}.${C_NC}"
	chmod 700 ${CAC_CA_DIR}/private

	echo -e "${C_GREEN}Setting ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_GREEN} serial to ${C_WHITE_BD}${START_SERIAL}${C_GREEN}.${C_NC}"
	echo "${START_SERIAL}" >> ${CAC_CA_DIR}/serial

	echo -e "${C_GREEN}Setting ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_GREEN} CRL number to ${C_WHITE_BD}${START_CRL_NUMBER}${C_GREEN}.${C_NC}"
	echo "${START_CRL_NUMBER}" >> ${CAC_CA_DIR}/crlnumber

	# Put CA OpenSSL config in place
	echo -e "${C_GREEN}Placing ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_GREEN} CA OpenSSL config at ${C_GREEN_BD}${CAC_CA_CONF_FILE}${C_NC}"
	cp ${CAC_CA_DIST_CONF_FILE} ${CAC_CA_CONF_FILE}

	# Set $dir in OpenSSL config file
	sed -E -i "s#^(dir)(\s*=\s*).*\$#\1\2${CAC_CA_PATH}#" ${CAC_CA_CONF_FILE}

	# Set private_key, certificate, crl filenames in OpenSSL config file
	sed -E -i "s#^(private_key)(\s*=\s*)(\\\$dir/private/).*\$#\1\2\3${CAC_CA_KEY_FILE_BARE}#" ${CAC_CA_CONF_FILE}
	sed -E -i "s#^(certificate)(\s*=\s*)(\\\$dir/certs/).*\$#\1\2\3${CAC_CA_CERT_FILE_BARE}#" ${CAC_CA_CONF_FILE}
	sed -E -i "s#^(crl)(\s*=\s*)(\\\$dir/crl/).*\$#\1\2\3${CAC_CA_CRL_FILE_BARE}#" ${CAC_CA_CONF_FILE}

	CAPTURE_DN_DEFAULTS="y"

	echo
	echo -e "Distinguished Name default values may be declared in the ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_NC}"
	echo -e "CA OpenSSL config file.  They may be entered here for inclusion in"
	echo "that file."
	echo
	echo "Certificate generation will prompt for Distingushed Name values;"
	echo "if you do not enter defaults here, the defaults used by certificate"
	echo "generation may not be desirable."
	echo
	echo -e "If you choose to set Distinguished Name defaults, only ${C_YELLOW_BD}emailAddress${C_NC}"
	echo "may be left blank."
	echo

	read -e -p "$( echo -e "Set Distingushed Name defaults for the ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_NC} CA? [${C_GREEN_BD}Y${C_NC}/n] ")" DNDEF
	DNDEF="${DNDEF:-${CAPTURE_DN_DEFAULTS}}"
	DNDEF="${DNDEF,,}"

	if [[ "${DNDEF}" == "${CAPTURE_DN_DEFAULTS}" ]]
	then
		echo -e "Please provide each of the following ...";

		for DNK in "${DN_PROMPTS_LIST[@]}"
		do
			DNT="${DN_PROMPTS[$DNK]}"
			DNV=""
			DNV_DEF=""

			if [[ "${CAC}" == intm ]]
			then
				if [[ "${DNK}" != organizationalUnitName ]]
				then
					DNV_DEF="${ROOT_CA_DN_DEFAULTS[$DNK]}"
				fi
			fi

			if [[ "${DNK}" == organizationalUnitName ]]
			then
				DNV_DEF="${CAC_CA_FULLNAME} CA"
			fi

			if [[ "${CAC}" == root ]] || [[ ! ' countryName stateOrProvinceName 0.organizationName ' =~ " ${DNK} " ]]
			then
				while [ -z "${DNV}" ]
				do
					read -e -p "$( echo -e "${DNT} (${C_YELLOW_BD}${DNK}${C_NC}): ")" -i "${DNV_DEF}" DNV

					if [[ "${DNK}" == countryName ]] && [[ ! "${DNV}" =~ ^[A-Za-z][A-Za-z]$ ]]
					then
						echo -e "${C_WHITE_YELLOW_BD}!!!${C_NC} Must be two letters."
						DNV=""
					fi

					if [[ "${DNK}" == emailAddress ]] && [[ -z ${DNV} ]]
					then
						break
					fi
				done

				if [[ "${DNK}" == countryName ]]
				then
					DNV="${DNV^^}"
				fi
			else
				echo -e "${DNT} (${C_YELLOW_BD}${DNK}${C_NC}) must match the ${C_CYAN_BD}${ROOT_CA_FULLNAME}${C_NC} CA value."
				echo -e "Using '${C_WHITE_BD}${ROOT_CA_DN_DEFAULTS[${DNK}]}${C_NC}'"

				DNV="${ROOT_CA_DN_DEFAULTS[${DNK}]}"
			fi

			CAC_CA_DN_DEFAULTS[${DNK}]="${DNV}"

			sed -E -i "s#^(${DNK}_default)(\s*=).*\$#\1\2 ${DNV}#" ${CAC_CA_CONF_FILE}
		done

		echo
		echo -e "${C_CYAN_BD}${CAC_CA_FULLNAME}${C_NC} CA Distinguished Name defaults:${C_CYAN}"
		echo
		grep -P '^\S+_default' ${CAC_CA_CONF_FILE}
		echo -e "${C_NC}"
	else
		echo -e "${C_YELLOW_BD}!!!${C_YELLOW} Not setting ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_YELLOW} CA Distinguished Name defaults.${C_NC}"
	fi

	echo -e "${C_GREEN}Creating ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_GREEN} CA Key...${C_NC}"
	echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} You must enter a 4 to 1024 character passphrase for the ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_YELLOW_BD} key.${C_NC}"
	echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} Keep it secret.  Keep it safe.${C_NC}"

	echo -e "${C_CYAN}Start Key Generation ===========================${C_NC}"
	openssl genrsa -aes256 -out ${CAC_CA_KEY_FILE} 4096
	CMD_RET=$?
	echo -e "${C_CYAN}Done ===========================================${C_NC}"

	if [ $CMD_RET -ne 0 ]
	then
		echo -e "${C_WHITE_RED_BD}!!!${C_RED} Command failed with status '${C_WHITE_BD}${CMD_RET}${C_RED}', aborting.${C_NC}"
		exit 1
	fi

	chmod 400 ${CAC_CA_KEY_FILE}

	# Create intermediate CSR
	if [[ "${CAC}" == intm ]]
	then
		echo -e "${C_GREEN}Creating ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_GREEN} Certificate Signing Request...${C_NC}"
		echo -e "${C_WHITE_RED_BD}!!!${C_YELLOW_BD} At the first prompt, enter the ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_YELLOW_BD} key passphrase from above to${C_NC}"
		echo -e "${C_WHITE_RED_BD}!!!${C_YELLOW_BD} generate the CSR.${C_NC}"
		echo
		echo "This process will prompt for Distinguished Name values using the"
		echo -e "defaults present in the ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_NC} OpenSSL config file."
		echo
		echo -e "${C_WHITE_YELLOW_BD}Note${C_NC}: ${C_YELLOW_BD}Common Name${C_NC} cannot be empty and must not contain spaces."
		echo -e "${C_WHITE_YELLOW_BD}Note${C_NC}: Each ${C_YELLOW_BD}Common Name${C_NC} value must be unique!"
		echo
		echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} Read the instructions carefully.${C_NC}"
		echo -e "${C_CYAN}Start CSR Creation =============================${C_NC}"
		openssl req -config ${CAC_CA_CONF_FILE} -new -sha512 -key ${CAC_CA_KEY_FILE} -out ${INTM_CA_CSR_FILE}
		CMD_RET=$?
		echo -e "${C_CYAN}Done ===========================================${C_NC}"

		if [ $CMD_RET -ne 0 ]
		then
			echo -e "${C_WHITE_RED_BD}!!!${C_RED} Command failed with status '${C_WHITE_BD}${CMD_RET}${C_RED}', aborting.${C_NC}"
			exit 1
		fi
	fi

	echo -e "${C_GREEN}Creating ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_GREEN} CA certificate...${C_NC}"

	if [[ "${CAC}" == root ]]
	then
		echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} When prompted, re-enter the ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_YELLOW_BD} key passphrase from above to${C_NC}"
		echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} generate this certificate.${C_NC}"
	else
		echo -e "${C_WHITE_RED_BD}!!!${C_YELLOW_BD} At the first prompt, re-enter the ${C_CYAN_BD}${ROOT_CA_FULLNAME}${C_YELLOW_BD} key passphrase from step one to${C_NC}"
		echo -e "${C_WHITE_RED_BD}!!!${C_YELLOW_BD} sign and generate the ${C_CYAN_BD}${INTM_CA_FULLNAME}${C_YELLOW_BD} certificate.${C_NC}"
	fi

	echo

	if [[ "${CAC}" == root ]]
	then
		echo "This process will prompt for Distinguished Name values using the"
		echo -e "defaults present in the ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_NC} OpenSSL config file."
		echo
		echo -e "${C_WHITE_YELLOW_BD}Note${C_NC}: ${C_YELLOW_BD}commonName${C_NC} cannot be empty and must not contain spaces."
		echo -e "${C_WHITE_YELLOW_BD}Note${C_NC}: Each ${C_YELLOW_BD}commonName${C_NC} value must be unique!"
		echo
		echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} Read the instructions carefully.${C_NC}"
	else
		echo -e "${C_YELLOW_BD}At the final two prompts, you must enter '${C_WHITE_BD}y${C_YELLOW_BD}' to confirm signing the${C_NC}"
		echo -e "${C_CYAN_BD}${CAC_CA_FULLNAME}${C_YELLOW_BD} Certificate and committing it to the ${C_CYAN_BD}${ROOT_CA_FULLNAME}${C_YELLOW_BD} CA index.${C_NC}"
	fi

	echo -e "${C_CYAN}Start Certificate Creation =====================${C_NC}"

	if [[ "${CAC}" == root ]]
	then
		openssl req -config ${CAC_CA_CONF_FILE} -key ${CAC_CA_KEY_FILE} -new -x509 -days ${CAC_CA_CERT_DAYS} -extensions v3_ca -out ${CAC_CA_CERT_FILE}
		CMD_RET=$?
	else
		openssl ca -config ${ROOT_CONF_FILE} -extensions v3_intermediate_ca -days ${CAC_CA_CERT_DAYS} -notext -md sha512 -in ${INTM_CA_CSR_FILE} -out ${CAC_CA_CERT_FILE}
		CMD_RET=$?
	fi

	echo -e "${C_CYAN}Done ===========================================${C_NC}"

	if [ $CMD_RET -ne 0 ]
	then
		echo -e "${C_WHITE_RED_BD}!!!${C_RED} Command failed with status '${C_WHITE_BD}${CMD_RET}${C_RED}', aborting.${C_NC}"
		exit 1
	fi

	echo -e "${C_GREEN}Setting permissions of ${C_GREEN_BD}${CAC_CA_CERT_FILE}${C_GREEN} to ${C_WHITE_BD}444${C_GREEN}.${C_NC}"
	chmod 444 ${CAC_CA_CERT_FILE}

	# Verify CA certificate
	echo -e "${C_GREEN}Verifying ${C_CYAN_BD}${CAC_CA_FULLNAME}${C_GREEN} CA certificate..."
	echo -e "${C_CYAN}Start Certificate Verification =================${C_NC}"
	openssl x509 -noout -text -in ${CAC_CA_CERT_FILE}
	CMD_RET=$?
	echo -e "${C_CYAN}Done ===========================================${C_NC}"

	if [ $CMD_RET -ne 0 ]
	then
		echo -e "${C_WHITE_RED_BD}!!!${C_RED} Command failed with status '${C_WHITE_BD}${CMD_RET}${C_RED}', aborting.${C_NC}"
		exit 1
	fi

	# Extra Intermediate steps
	if [[ "${CAC}" == intm ]]
	then
		# Verify Intermediate cert against Root cert
		echo -e "Verifying ${C_CYAN_BD}${INTM_CA_FULLNAME}${C_NC} cert against ${C_CYAN_BD}${ROOT_CA_FULLNAME}${C_NC} cert..."
		echo -e "${C_CYAN}Start Signature Verification ===================${C_NC}"

		openssl verify -CAfile ${ROOT_CA_CERT_FILE} ${INTM_CA_CERT_FILE}
		CMD_RET=$?
		echo -e "${C_CYAN}Done ===========================================${C_NC}"

		if [ $CMD_RET -ne 0 ]
		then
			echo -e "${C_WHITE_RED_BD}!!!${C_RED} Command failed with status '${C_WHITE_BD}${CMD_RET}${C_RED}', aborting.${C_NC}"

			exit 1
		fi

		echo -e "${C_GREEN}Creating certificate chain file at ${C_GREEN_BD}${INTM_CA_CHAIN_FILE}${C_NC}"
		cat ${INTM_CA_CERT_FILE} ${ROOT_CA_CERT_FILE} >> ${INTM_CA_CHAIN_FILE}
	fi

	echo
	echo -e "${C_YELLOW_GREEN_BD} ${C_WHITE_GREEN_BD}${CAC_CA_FULLNAME}${C_YELLOW_GREEN_BD} CA setup complete! ${C_NC}"
	echo
done

echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo -e "${C_WHITE_BLUE_BD}# Hosts Configuration                              #${C_NC}"
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"

echo -e "${C_GREEN}Preparing hosts directory ${C_GREEN_BD}${HOSTS_CA_PATH}${C_GREEN} ...${C_NC}"

if [ -d ${HOSTS_DIR_BASE} ]
then
	echo -e "${C_WHITE_RED_BD}!!!${C_RED} Hosts directory ${C_RED_BD}${HOSTS_DIR_BASE}${C_RED} found.${C_NC}"
	echo -e "${C_WHITE_RED_BD}!!!${C_RED} Aborting setup.${C_NC}"

	exit 1
else
	echo -e "${C_GREEN}Creating hosts directory ${C_GREEN_BD}${HOSTS_DIR_BASE}${C_NC}"
	mkdir ${HOSTS_DIR_BASE}
fi

mkdir ${HOSTS_DIR_BASE}/private
chmod 700 ${HOSTS_DIR_BASE}/private
mkdir ${HOSTS_DIR_BASE}/csr
mkdir ${HOSTS_DIR_BASE}/certs
mkdir ${HOSTS_DIR_BASE}/conf

echo

# Capture Host Distringuished Name defaults
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo -e "${C_WHITE_BLUE_BD}# Host Distinguished Name defaults                 #${C_NC}"
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo
echo "These values are used to generate host server certificates.  They are"
echo "stored in the Certificate Authority config file and populated into each"
echo "host's OpenSSL config file, located at"
echo
echo -e "    ${C_GREEN_BD}${HOSTS_CA_PATH}/conf/${C_MAGENTA_BD}[host name]${C_GREEN_BD}.${HOST_DOMAIN_NAME}${HOSTS_CONFIG_FILE_BASE}${C_GREEN_BD}${C_NC}"
echo
echo -e "For convenience, corresponding values from the ${C_CYAN_BD}${INTM_CA_FULLNAME}${C_NC} OpenSSL config"
echo "file are provided as defaults in the following prompts."
echo
echo -e "If these are not configured, host CSR generation will prompt for them anyway."
echo
echo "These defaults are stored in the Certificate Authority config file:"
echo
echo -e "    ${C_GREEN_BD}${CA_BASE_PATH}/${CA_CONFIG_FILE}${C_NC}"
echo

CAPTURE_HDN_DEFAULTS="y"

read -e -p "$( echo -e "Set host Distingushed Name defaults? [${C_GREEN_BD}Y${C_NC}/n] ")" HDNDEF
HDNDEF="${HDNDEF:-${CAPTURE_HDN_DEFAULTS}}"
HDNDEF="${HDNDEF,,}"
#echo "${HDNDEF}"

#set -o xtrace
if [[ "${HDNDEF}" == "${CAPTURE_HDN_DEFAULTS}" ]]
then
	echo -e "Please provide each of the following (no empty values accepted):";
	echo
	for HDNK in "${HDN_PROMPTS_LIST[@]}"
	do
		HDNT="${HDN_PROMPTS[$HDNK]}"
		HDNC="${HOST_CONFIG_MAP[$HDNK]}"

		INTM_DEFAULT_KEY="${HOST_INTM_DN_MAP[$HDNK]}"

		INTM_HOST_DN_LINE=$(grep -P "^${INTM_DEFAULT_KEY}\\s*=\\s*.*$" ${INTM_CONF_FILE} |xargs)

		INTM_HOST_DN_DEF=$(sed -E "s#${INTM_DEFAULT_KEY}\\s*=\\s*(.*)?\\s*#\\1#" <<< "${INTM_HOST_DN_LINE}")

		HDNV=""

		while [ -z "${HDNV}" ]
		do
			read -e -p "$( echo -e "${HDNT} (${C_YELLOW_BD}${HDNK}${C_NC}): ")" -i "${INTM_HOST_DN_DEF}" HDNV

			HDNV=$(echo "${HDNV}" |xargs)

			if [[ "${HDNK}" == C ]] && [[ ! "${HDNV}" =~ ^[A-Za-z][A-Za-z]$ ]]
			then
				echo -e "${C_WHITE_YELLOW_BD}!!!${C_NC} Must be two letters."
				HDNV=""
			fi
		done

		if [[ "${HDNK}" == C ]]
		then
			HDNV="${HDNV^^}"
		fi

		sed -E -i "s#^(${HDNC})\s*=\s*.*\$#\1=\"${HDNV}\"#" ${CA_BASE_PATH}/${CA_CONFIG_FILE}
	done

	echo
	echo -e "${C_WHITE_GREEN_BD}!!!${C_NC} Finished."
	echo
	echo -e "Host Distinguished Name defaults:${C_CYAN}"
	grep -P '^HOST_DEFAULT_\w+' ${CA_BASE_PATH}/${CA_CONFIG_FILE}
	echo -e "${C_NC}"
else
	echo -e "${C_YELLOW_BD}!!!${C_YELLOW} Not setting host Distinguished Name defaults.${C_NC}"
fi

echo -e "These may be changed by editing ${C_GREEN_BD}${CA_BASE_PATH}/${CA_CONFIG_FILE}${C_NC}"

echo
echo -e "${C_YELLOW_GREEN_BD}****************************************************${C_NC}"
echo -e "${C_YELLOW_GREEN_BD}* ${C_WHITE_GREEN_BD}Certificate Authority successfully configured!${C_YELLOW_GREEN_BD}   *${C_NC}"
echo -e "${C_YELLOW_GREEN_BD}****************************************************${C_NC}"
echo

echo
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo -e "${C_WHITE_BLUE_BD}# Next Steps                                       #${C_NC}"
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo
echo -e "${C_WHITE_BD}Replace all this... ${C_NC}"
echo -e "${C_CYAN_BD}${ROOT_CA_FULLNAME}${C_NC} Certificate: ${C_GREEN_BD}${ROOT_CA_CERT_FILE}${C_NC}"
echo -e "${C_CYAN_BD}${INTM_CA_FULLNAME}${C_NC} Certificate: ${C_GREEN_BD}${INTM_CA_CERT_FILE}${C_NC}"
echo -e "${C_CYAN_BD}Chain File${C_NC}: ${C_GREEN_BD}${INTM_CA_CHAIN_FILE}${C_NC}"



echo "===================================================="

echo -e "${C_MAGENTA_BD}=======================================${C_NC}"

echo

exit

