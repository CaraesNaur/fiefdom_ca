#!/bin/bash

# Go to script location
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")"

source includes/common.sh

CA_BASE_PATH=$(pwd)

if [ ! -f ${CA_BASE_PATH}/${CA_CONFIG_FILE} ]
then
	echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} Certificate authority config file is missing!${C_NC}"
	echo -e "${C_YELLOW}Perhaps ${C_GREEN_BD}ca_setup.sh${C_YELLOW} has not been run yet?  Aborting."

	exit 1
fi

source ${CA_BASE_PATH}/${CA_CONFIG_FILE}

################################################
# Basic config checks                          #
################################################
for CV in ROOT_CA_CERT_FILE ROOT_CA_DIR ROOT_CA_FULLNAME ROOT_CA_KEY_FILE ROOT_CA_PATH ROOT_CONF_FILE INTM_CA_CERT_FILE INTM_CA_DIR INTM_CA_CHAIN_FILE INTM_CA_FULLNAME INTM_CA_KEY_FILE INTM_CA_PATH INTM_CONF_FILE HOSTS_CA_PATH HOST_DOMAIN_NAME HOST_CERT_DAYS
do
	declare "CVC=${CV}"

	if [ -z "${!CVC+x}" ]
	then
		echo -e "${C_WHITE_RED_BD}!!!${C_RED} Config value '${C_RED_BD}${CVC}${C_RED}' Missing.  Aborting...${C_NC}"

		exit 1
	fi

	if [[ "${CV}" =~ _PATH$ ]]
	then
		if [[ ! -d ${!CVC} ]]
		then
			echo -e "${C_WHITE_RED_BD}!!!${C_RED} Configured path ${C_YELLOW_BD}${CVC}${C_RED} missing: ${C_RED_BD}${!CVC}${C_RED}.  Aborting...${C_NC}"

			exit 1
		fi
	fi

	if [[ "${CV}" =~ _DIR$ ]]
	then
		if [[ ! -d ${CA_BASE_PATH}/${!CVC} ]]
		then
			echo -e "${C_WHITE_RED_BD}!!!${C_RED} Configured directory ${C_YELLOW_BD}${CVC}${C_RED} missing: ${C_RED_BD}${!CVC}${C_RED}.  Aborting...${C_NC}"

			exit 1
		fi
	fi

	if [[ "${CV}" =~ _FILE$ ]]
	then
		if [[ ! -f ${!CVC} ]]
		then
			echo -e "${C_WHITE_RED_BD}!!!${C_RED} Configured file ${C_YELLOW_BD}${CVC}${C_RED} missing: ${C_RED_BD}${!CVC}${C_RED}.  Aborting...${C_NC}"

			exit 1
		fi
	fi
done

while getopts h: option
do
	case "${option}"
	in
		h) THIS_HOST_NAME=${OPTARG,,};;
	esac
done

if [[ ! "${THIS_HOST_NAME}" =~ ${HOST_MATCH} ]]
then
	echo -e "${C_WHITE_RED_BD}!!!${C_RED} Invalid host name '${C_RED_BD}${THIS_HOST_NAME}${C_RED}' given, aborting.  Did you pass the ${C_WHITE_BD}-h${C_RED} argument?${C_NC}"
	exit 2
fi

# Establish filenames
HOST_DNS_NAME="${THIS_HOST_NAME}.${HOST_DOMAIN_NAME}"
HOST_KEY_FILE_BARE="${HOST_DNS_NAME}${HOSTS_KEY_FILE_BASE}"
HOST_CSR_FILE_BARE="${HOST_DNS_NAME}${HOSTS_CSR_FILE_BASE}"
HOST_CRT_FILE_BARE="${HOST_DNS_NAME}${HOSTS_CRT_FILE_BASE}"
HOST_CONF_FILE_BARE="${HOST_DNS_NAME}${HOSTS_CONFIG_FILE_BASE}"

HOST_KEY_FILE="${HOSTS_CA_PATH}/private/${HOST_KEY_FILE_BARE}"
HOST_CSR_FILE="${HOSTS_CA_PATH}/csr/${HOST_CSR_FILE_BARE}"
HOST_CRT_FILE="${HOSTS_CA_PATH}/certs/${HOST_CRT_FILE_BARE}"
HOST_CONF_FILE="${HOSTS_CA_PATH}/conf/${HOST_CONF_FILE_BARE}"

MY_INTM_CONF_FILE_BARE="${THIS_HOST_NAME}_host_tmp_$(basename ${INTM_CONF_FILE})"
MY_INTM_CONF_FILE="${INTM_CA_PATH}/${MY_INTM_CONF_FILE_BARE}"

CA_DEPLOYMENTS_FILE="${CA_BASE_PATH}/${CA_DEPLOYMENTS_FILE_BARE}"

# Create host OpenSSL config file
echo -e "${C_GREEN}Preparing to generate OpenSSL assets for ${C_CYAN_BD}${HOST_DNS_NAME}${C_GREEN} ...${C_NC}"

echo -e "${C_GREEN}Creating config file ${C_GREEN_BD}${HOST_CONF_FILE}${C_GREEN} ...${C_NC}"
cp ${CA_BASE_PATH}/dist_files/host_openssl.conf.dist ${HOST_CONF_FILE}

echo -e "${C_GREEN}Creating temporary ${C_CYAN_BD}${INTM_CA_FULLNAME}${C_GREEN} config file ${C_GREEN_BD}${MY_INTM_CONF_FILE}${C_GREEN} ...${C_NC}"
cp ${INTM_CONF_FILE} ${MY_INTM_CONF_FILE}


# Inject Subject Alternate Name lines into tmp INTM config

SAN_AT_LINE=$(grep -nP '^\[ [\w_]+ \]' ${MY_INTM_CONF_FILE} |grep -A1 '\[ server_cert \]' |tail -1|cut -f 1 -d':')

sed -i "${SAN_AT_LINE}i# added for SAN\\nsubjectAltName=@my_subject_alt_names\\n\\n[ my_subject_alt_names ]\\nDNS.1 = ${HOST_DNS_NAME}\\n" ${MY_INTM_CONF_FILE}

# Populate DN values into host config
for HDNK in "${HDN_PROMPTS_LIST[@]}"
do
	HDNT="${HDN_PROMPTS[$HDNK]}"
	HDNC="${HOST_CONFIG_MAP[$HDNK]}"
	declare -n "HDNV=${HDNC}"

	sed -i -E "s#^(${HDNK})(\s*=)\s*.*\$#\1\2 ${HDNV}#" ${HOST_CONF_FILE}
done

# Set Common Name and DNS.1 in host config
sed -i -E "s#^(CN)(\s*=)\s*.*\$#\1\2 ${HOST_DNS_NAME}#" ${HOST_CONF_FILE}
sed -i -E "s#^(DNS\.1)(\s*=)\s*.*\$#\1\2 ${HOST_DNS_NAME}#" ${HOST_CONF_FILE}

# Create host key
echo
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo -e "${C_WHITE_BLUE_BD}# Host Key                                         #${C_NC}"
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"

if [ ! -f "${HOST_KEY_FILE}" ]
then
	echo -e "${C_GREEN}Generating key for ${C_CYAN_BD}${HOST_DNS_NAME}${C_GREEN} ..."
	echo

    echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} Host keys are generated without a passphrase.  This allows services${C_NC}"
	echo -e "${C_YELLOW_BD}to (re)start without the need to prompt for them.${C_NC}"
	echo
	echo -e "${C_WHITE_YELLOW_BD}Note${C_NC}: The following may produce no output."
	echo -e "${C_CYAN}Start Key Generation ===============================${C_NC}"
	openssl genrsa -out ${HOST_KEY_FILE} 2048
	CMD_RET=$?
	echo -e "${C_CYAN}Done ===============================================${C_NC}"

	if [ ${CMD_RET} -ne 0 ]
	then
		echo -e "${C_WHITE_RED_BD}!!!${C_RED} Key creation failed, aborting.${C_NC}"

		exit 1
	else
		echo -e "${C_GREEN}Host key OK: ${C_GREEN_BD}${HOST_KEY_FILE}${C_NC}"
	fi
else
	echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW} Host key file for ${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW} already exists:${C_NC}"
	echo -e "${C_GREEN_BD}${HOST_KEY_FILE}${C_NC}"
fi

chmod 400 ${HOST_KEY_FILE}

# Create host CSR
echo
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo -e "${C_WHITE_BLUE_BD}# Host Certificate Signing Request                 #${C_NC}"
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"

if [ ! -f "${HOST_CSR_FILE}" ]
then
	echo -e "${C_GREEN}Generating Certificate Signing Request for ${C_CYAN_BD}${HOST_DNS_NAME}${C_GREEN} ...${C_NC}"
	echo
	echo -e "${C_WHITE_YELLOW_BD}Note${C_NC}: The following may produce no output."
	echo -e "${C_CYAN}Start CSR Creation =================================${C_NC}"
	openssl req -config ${HOST_CONF_FILE} -key ${HOST_KEY_FILE} -new -sha512 -out ${HOST_CSR_FILE}
	CMD_RET=$?
	echo -e "${C_CYAN}Done ===============================================${C_NC}"

	if [ ${CMD_RET} -ne 0 ]
	then
		echo -e "${C_WHITE_RED_BD}!!!${C_RED} CSR creation failed, aborting.${C_NC}"

		exit 1
	else
		echo -e "${C_GREEN}Host CSR OK: ${C_GREEN_BD}${HOST_CSR_FILE}${C_NC}"
	fi
else
	echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW} CSR Already exists: ${C_GREEN_BD}${HOST_CSR_FILE}${C_NC}"
fi

echo

# Optionally examine CSR
EXAMINE_CSR="y"

read -e -p "$( echo -e "Examine ${C_CYAN_BD}${HOST_DNS_NAME}${C_NC} CSR? [${C_GREEN_BD}Y${C_NC}/n] ")" ECSR
ECSR="${ECSR:-${EXAMINE_CSR}}"
ECSR="${ECSR,,}"

if [[ "${ECSR}" == "${EXAMINE_CSR}" ]]
then
	echo -e "${C_CYAN}Start CSR Examination ==============================${C_NC}"
	openssl req -text -noout -verify -in ${HOST_CSR_FILE}
	CMD_RET=$?
	echo -e "${C_CYAN}Done ===============================================${C_NC}"

	if [ ${CMD_RET} -ne 0 ]
	then
		echo -e "${C_WHITE_RED_BD}!!!${C_RED} CSR examination failed, aborting.${C_NC}"

		exit 1
	fi
else
	echo -e "${C_YELLOW_BD}!!!${C_YELLOW} Not examining ${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW} CSR.${C_NC}"
fi

# Generate host certificate
echo
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo -e "${C_WHITE_BLUE_BD}# Host Certificate                                 #${C_NC}"
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"

if [ -f "${HOST_CRT_FILE}" ]
then
	# TODO: revoke certificate
	OVERWRITE_CRT="Yes"
	OWCRT1=""
	OWCRT2=""

	echo -e "${C_WHITE_YELLOW_BD}!!!${C_RED} Certificate for ${C_CYAN_BD}${HOST_DNS_NAME}${C_RED} already exists:${C_NC}"
	echo -e "${C_GREEN_BD}${HOST_CRT_FILE}${C_NC}"

	read -e -p "$( echo -e "${C_YELLOW_BD}Overwrite ${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW_BD} certificate? Enter 'Yes': ${C_NC}")" OWCRT1

	if [[ "${OWCRT1}" == "${OVERWRITE_CRT}" ]]
	then
		read -e -p "$( echo -e "${C_YELLOW_BD}*** Are you sure? *** Enter 'Yes' again: ${C_NC}")" OWCRT2
	fi

	if [ "${OWCRT1}" != "${OVERWRITE_CRT}" -o "$OWCRT2" != "${OVERWRITE_CRT}" ]
	then
		echo
		echo -e "${C_WHITE_YELLOW_BD}!!!${C_RED} Aborting.${C_NC}"
		echo

		exit 1
	fi

	rm ${HOST_CRT_FILE}

	echo
	echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD}Existing certificate for ${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW_BD} deleted.${C_NC}"
	echo
fi

echo -e "${C_GREEN}Signing ${C_CYAN_BD}${HOST_DNS_NAME}${C_GREEN} certificate using ${C_CYAN_BD}${INTM_CA_FULLNAME}${C_GREEN} CA...${C_NC}"
echo
CRT_DAYS_DEF="${HOST_CERT_DAYS_DEFAULT}"

echo -e "${C_WHITE_YELLOW_BD}NOTE${C_YELLOW_BD}: As of ${C_WHITE_BD}1 Sept 2020${C_YELLOW_BD}, maximum certificate validity period is ${C_WHITE_BD}397${C_YELLOW_BD} days.${C_NC}"
echo -e "${C_YELLOW_BD}You may accept that or enter a lower number here.${C_NC}"
echo
MY_CRT_DAYS=${CRT_DAYS_DEF}

CRT_DAYS_OK=false

while [[ "${CRT_DAYS_OK}" == false ]]
do
	read -p "Certificate validity period: " -i "${MY_CRT_DAYS}" -e MY_CRT_DAYS

	if [[ "${MY_CRT_DAYS}" =~ ^[1-9][0-9]+$ ]] && [[ ${MY_CRT_DAYS} -le ${CRT_DAYS_DEF} ]]
	then
		CRT_DAYS_OK=true
	fi
done

echo
echo -e "${C_GREEN}Certificate will be valid for ${C_WHITE_BD}${MY_CRT_DAYS}${C_GREEN} days, until approximately${C_NC}"
echo -e "${C_WHITE_BD}"$(date --date="now +${MY_CRT_DAYS} days" -R)"${C_GREEN} (${C_WHITE_BD}$(date -u --date="now +${MY_CRT_DAYS} days" -R)${C_GREEN}).${C_NC}"

echo
echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} When prompted, enter the ${C_CYAN_BD}${INTM_CA_FULLNAME}${C_YELLOW_BD} key passphrase to${C_NC}"
echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} sign and generate the ${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW_BD} certificate.${C_NC}"
echo
echo -e "${C_YELLOW_BD}At the final two prompts, you must enter 'y' to confirm signing the${C_NC}"
echo -e "${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW_BD} certificate and committing it to the ${C_CYAN_BD}${INTM_CA_FULLNAME}${C_YELLOW_BD} CA index.${C_NC}"


echo -e "${C_CYAN}Start Certificate Creation =========================${C_NC}"

openssl ca -config ${MY_INTM_CONF_FILE} -extensions server_cert -days ${MY_CRT_DAYS} -notext -md sha512 -in ${HOST_CSR_FILE} -out ${HOST_CRT_FILE}
CMD_RET=$?

echo -e "${C_CYAN}Done ===============================================${C_NC}"

if [ ${CMD_RET} -eq 0 ]
then
	echo -e "${C_GREEN}Certificate for ${C_CYAN_BD}${HOST_DNS_NAME}${C_GREEN} created at ${C_GREEN_BD}${HOST_CRT_FILE}${C_NC}"
else
	echo -e "${C_WHITE_RED_BD}!!!${C_RED} Certificate creation failed, aborting.${C_NC}"

	exit 1
fi

# Optionally examine certificate
EXAMINE_CRT="y"

echo
read -e -p "$( echo -e "Examine ${C_CYAN_BD}${HOST_DNS_NAME}${C_NC} certificate? [${C_GREEN_BD}Y${C_NC}/n] ")" ECRT
ECRT="${ECRT:-${EXAMINE_CRT}}"
ECRT="${ECRT,,}"

if [[ "${ECRT}" == "${EXAMINE_CRT}" ]]
then
	echo -e "${C_CYAN}Start Certificate Examination ======================${C_NC}"
	openssl x509 -noout -text -in ${HOST_CRT_FILE}
	CMD_RET=$?
	echo -e "${C_CYAN}Done ===============================================${C_NC}"

	if [ ${CMD_RET} -ne 0 ]
	then
		echo -e "${C_WHITE_RED_BD}!!!${C_RED} Certificate examination failed, aborting.${C_NC}"

		exit 1
	fi
else
	echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW} Not examining ${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW} certificate.${C_NC}"
fi

echo
echo -e "${C_YELLOW_GREEN_BD}****************************************************${C_NC}"
echo -e "${C_YELLOW_GREEN_BD}* ${C_WHITE_GREEN_BD}SSL assets generated successfully!${C_YELLOW_GREEN_BD}               *${C_NC}"
echo -e "${C_YELLOW_GREEN_BD}****************************************************${C_NC}"
echo

echo -e "Identity files for ${C_CYAN_BD}${HOST_DNS_NAME}${C_NC}:"
echo -e "Key: ${C_GREEN_BD}${HOST_KEY_FILE}${C_NC}"
echo -e "Certificate: ${C_GREEN_BD}${HOST_CRT_FILE}${C_NC}"
echo
echo -e "Remember to include the ${C_CYAN_BD}${INTM_CA_FULLNAME}${C_NC} chain file."
echo -e "Chain File: ${C_GREEN_BD}${INTM_CA_CHAIN_FILE}${C_NC}"
echo

# Optionally deploy host identity to services
if [[ ! -f "${CA_DEPLOYMENTS_FILE}" ]]
then
	echo -e "${C_YELLOW_BD}!!!${C_YELLOW} Deployments file not found: ${C_GREEN_BD}${CA_DEPLOYMENTS_FILE}${C_NC}"
	echo -e "${C_YELLOW_BD}${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW} identity must be deployed manually.${C_NC}"

	exit
fi

DEPLOY_IDENT="y"

echo
read -e -p "$( echo -e "Deploy ${C_CYAN_BD}${HOST_DNS_NAME}${C_NC} identity files? [${C_GREEN_BD}Y${C_NC}/n] ")" DIDENT

DIDENT="${DIDENT:-${DEPLOY_IDENT}}"
DIDENT="${DIDENT,,}"

if [[ "${DIDENT}" == "${DEPLOY_IDENT}" ]]
then
	echo
	./host_deploy.sh -h "${THIS_HOST_NAME}"
else
	echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW} Not deploying ${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW} identity.${C_NC}"
fi

exit
