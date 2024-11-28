#!/bin/bash

# Go to script location
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")"

source includes/common.sh

CA_BASE_PATH=$(pwd)

echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo -e "${C_WHITE_BLUE_BD}# Host Identity Deployment                         #${C_NC}"
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"

if [ ! -f ${CA_BASE_PATH}/${CA_CONFIG_FILE} ]
then
	echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} Certificate authority config file is missing!${C_NC}"
	echo -e "${C_YELLOW}Perhaps ${C_GREEN_BD}ca_setup.sh${C_YELLOW} has not been run yet?  Aborting."

	exit 1
fi

source ${CA_BASE_PATH}/${CA_CONFIG_FILE}

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
			else
				echo -e "Configured path ${C_GREEN}${CVC}${C_NC} ${C_GREEN_BD}${!CVC}${C_NC} exists."
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

CA_DEPLOYMENTS_FILE="${CA_BASE_PATH}/${CA_DEPLOYMENTS_FILE_BARE}"

DEPLOY_COUNT=0
DEPLOY_SERVICES=()
DEPLOY_PATHS=()

DEPLOY_GO=true

for DEPFILE in KEY CSR CRT CONF
do
	REQ_FILE="HOST_${DEPFILE}_FILE"

	case ${DEPFILE} in
		KEY)
			REQ_LABEL="${DEPFILE,,}";;
		CSR)
			REQ_LABEL="${DEPFILE}";;
		CRT)
			REQ_LABEL="certificate";;
		CONF)
			REQ_LABEL="config";;
	esac

	if [[ ! -f "${!REQ_FILE}" ]]
	then
		echo -e "${C_RED}Missing ${REQ_LABEL} file for ${C_CYAN_BD}${HOST_DNS_NAME}${C_RED}: ${C_RED_BD}${!REQ_FILE}${C_NC}"

		DEPLOY_GO=false
	else
		echo -e "${C_GREEN}Found ${REQ_LABEL} file for ${C_CYAN_BD}${HOST_DNS_NAME}${C_GREEN}: ${C_GREEN_BD}${!REQ_FILE}${C_NC}"
	fi
done

echo

if [[ "${DEPLOY_GO}" == false ]]
then
	echo -e "${C_RED}One or more required files for ${C_CYAN_BD}${HOST_DNS_NAME}${C_RED} not found, aborting.${C_NC}"

	exit 2
fi

echo -e "${C_GREEN}Deploying ${C_CYAN_BD}${HOST_DNS_NAME}${C_GREEN} identity files as configured in${C_NC}"
echo -e "${C_GREEN_BD}${CA_DEPLOYMENTS_FILE}${C_NC}"
echo

DEPLOY_IDENT="y"

read -e -p "$( echo -e "Deploy ${C_CYAN_BD}${HOST_DNS_NAME}${C_NC} identity files? [${C_GREEN}Y${C_NC}/n] ")" DIDENT
DIDENT="${DIDENT:-${DEPLOY_IDENT}}"
DIDENT="${DIDENT,,}"

if [[ "${DIDENT}" == "${DEPLOY_IDENT}" ]]
then
	echo -e "${C_GREEN}Deploying ${C_CYAN_BD}${HOST_DNS_NAME}${C_GREEN} to services configured in${C_NC}"
	echo -e "${C_GREEN_BD}${CA_DEPLOYMENTS_FILE}${C_GREEN} ...${C_NC}"

	CA_DEP_SECS=$(./iniget ${CA_DEPLOYMENTS_FILE} -l)
	CA_DEP_SECS_COUNT=$(echo -n "${CA_DEP_SECS}" |grep -Pc '^')

	echo -e "Current possible deployments: ${C_WHITE_BD}${CA_DEP_SECS_COUNT}${C_NC}"
	echo

	if [[ ${CA_DEP_SECS_COUNT} -gt 0 ]]
	then
		echo "Each viable deployment will be prompted for action..."
		echo

		IFS=$'\n'

		for DST in ${CA_DEP_SECS}
		do
			DEP_PATH=$(./iniget ${CA_DEPLOYMENTS_FILE} "${DST}" path)
			DEP_SVC=$(./iniget ${CA_DEPLOYMENTS_FILE} "${DST}" service)
			DEPLOY_PATHS+=("${DEP_PATH}")

			DEP_PATH_OK=false
			DEP_SVC_OK=false
			DEP_PATH_STAT=""
			DEP_SVC_STAT=""

			if [[ -z "${DEP_PATH}" ]]
			then
				DEP_PATH_STAT="${C_RED}No path set${C_NC}"
			elif [[ ! -d "${DEP_PATH}" ]]
			then
				DEP_PATH_STAT="${C_RED}Not found: ${C_RED_BD}${DEP_PATH}${C_NC}"
			elif [[ $(grep -P -c "^path\s*=\s*${DEP_PATH}$" ${CA_DEPLOYMENTS_FILE}) -ne 1 ]]
			then
				DEP_PATH_STAT="${C_RED}Duplicate path: ${C_RED_BD}${DEP_PATH}${C_NC}"
			else
				DEP_PATH_STAT="${C_GREEN_BD}${DEP_PATH}${C_NC}"
				DEP_PATH_OK=true
			fi

			if [[ -z "${DEP_SVC}" ]]
			then
				DEP_SVC_STAT="${C_RED}No service set${C_NC}"
			elif ! systemctl list-unit-files ${DEP_SVC}.service &>/dev/null
			then
				DEP_SVC_STAT="${C_RED}Service not found: ${C_RED_BD}${DEP_SVC}${C_NC}"
			else
				DEP_SVC_STAT="${C_GREEN_BD}${DEP_SVC}${C_NC}"
				DEP_SVC_OK=true
			fi

			if [[ "${DEP_PATH_OK}" == true && "${DEP_SVC_OK}" == true ]]
			then
				echo -e "${C_YELLOW_GREEN_BD}***${C_GREEN} Deployment: ${C_WHITE_BD}${DST}${C_NC}"
			else
				echo -e "${C_WHITE_RED_BD}!!!${C_RED} Deployment: ${C_WHITE_BD}${DST}${C_NC}"
			fi

			echo -e "${C_CYAN}To: ${DEP_PATH_STAT}"
			echo -e "${C_CYAN}For: ${DEP_SVC_STAT}"
			echo

			if [[ "${DEP_PATH_OK}" == true && "${DEP_SVC_OK}" == true ]]
			then
				DEP_KEY_EXISTS=false
				DEP_CRT_EXISTS=false

				if [[ -f "${DEP_PATH}/${HOST_KEY_FILE_BARE}" ]]
				then
					DEP_KEY_EXISTS=true
				fi

				if [[ -f "${DEP_PATH}/${HOST_CRT_FILE_BARE}" ]]
				then
					DEP_CRT_EXISTS=true
				fi

				if [[ "${DEP_KEY_EXISTS}" == false && "${DEP_CRT_EXISTS}" == false ]]
				then
					echo -e "${C_YELLOW_GREEN_BD} Deployment OK! ${C_GREEN} Deploy ${C_CYAN_BD}${HOST_DNS_NAME}${C_GREEN} identity:${C_NC}"
					echo -e "Key: ${C_GREEN_BD}${DEP_PATH}/${HOST_KEY_FILE_BARE}${C_NC}"
					echo -e "Certificate: ${C_GREEN_BD}${DEP_PATH}/${HOST_CRT_FILE_BARE}${C_NC}"

					read -e -p "$( echo -e "Deploy? [${C_GREEN_BD}Y${C_NC}/n] ")" DIDENT
					DIDENT="${DIDENT:-${DEPLOY_IDENT}}"
					DIDENT="${DIDENT,,}"

					if [[ "${DIDENT}" == "${DEPLOY_IDENT}" ]]
					then
						cp -a ${HOST_KEY_FILE} ${DEP_PATH}/${HOST_KEY_FILE_BARE}
						chmod 644 ${DEP_PATH}/${HOST_KEY_FILE_BARE}
						cp -a ${HOST_CRT_FILE} ${DEP_PATH}/${HOST_CRT_FILE_BARE}
						chmod 644 ${DEP_PATH}/${HOST_CRT_FILE_BARE}

						((DEPLOY_COUNT++))
						DEPLOY_SERVICES+=( "${DEP_SVC}" )

						echo -e "${C_CYAN_BD}${HOST_DNS_NAME}${C_GREEN} identity deployed to ${C_WHITE_BD}${DST}${C_GREEN}!${C_NC}"
					else
						echo -e "${C_YELLOW}Not deploying ${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW} identity to ${C_WHITE_BD}${DST}${C_YELLOW}.${C_NC}"
					fi

				else
					echo -e "${C_WHITE_RED_BD}!!!${C_YELLOW_BD} One or more identity files already exist!${C_NC}"


					if [[ "${DEP_KEY_EXISTS}" == true ]]
					then
						echo -e "Key: ${C_RED_BD}${DEP_PATH}/${HOST_KEY_FILE_BARE}${C_NC}"
					else
						echo -e "Key: ${C_GREEN_BD}${DEP_PATH}/${HOST_KEY_FILE_BARE}${C_NC}"
					fi

					if [[ "${DEP_CRT_EXISTS}" == true ]]
					then
						echo -e "Certificate: ${C_RED_BD}${DEP_PATH}/${HOST_CRT_FILE_BARE}${C_NC}"
					else
						echo -e "Certificate: ${C_GREEN_BD}${DEP_PATH}/${HOST_CRT_FILE_BARE}${C_NC}"
					fi

					DEP_PRESERVE_STAMP=$(date +%Y%m%d_%H%I%S.%N)

					read -e -p "$( echo -e "${C_YELLOW_BD}Deploy anyway? [Y] ${C_NC} ")" DIDENT
					DIDENT="${DIDENT:0:1}"

					if [[ "${DIDENT}" == "${DEPLOY_IDENT^^}" ]]
					then
						if [[ "${DEP_KEY_EXISTS}" == true ]]
						then
							echo -e "${C_RED}Preserving key as ${C_RED_BD}${DEP_PATH}/${HOST_KEY_FILE_BARE}.${DEP_PRESERVE_STAMP}${C_NC}"
							mv ${DEP_PATH}/${HOST_KEY_FILE_BARE} ${DEP_PATH}/${HOST_KEY_FILE_BARE}.${DEP_PRESERVE_STAMP}
						fi

						cp -a ${HOST_KEY_FILE} ${DEP_PATH}/${HOST_KEY_FILE_BARE}
						chmod 644 ${DEP_PATH}/${HOST_KEY_FILE_BARE}

						if [[ "${DEP_CRT_EXISTS}" == true ]]
						then
							echo -e "${C_RED}Preserving certificate as ${C_RED_BD}${DEP_PATH}/${HOST_CRT_FILE_BARE}.${DEP_PRESERVE_STAMP}${C_NC}"
							mv ${DEP_PATH}/${HOST_CRT_FILE_BARE} ${DEP_PATH}/${HOST_CRT_FILE_BARE}.${DEP_PRESERVE_STAMP}
						fi

						cp -a ${HOST_CRT_FILE} ${DEP_PATH}/${HOST_CRT_FILE_BARE}
						chmod 644 ${DEP_PATH}/${HOST_CRT_FILE_BARE}

						((DEPLOY_COUNT++))
						DEPLOY_SERVICES+=( "${DEP_SVC}" )
					else
						echo -e "${C_YELLOW}Not replacing deployment of ${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW} identity at ${C_WHITE_BD}${DST}${C_YELLOW}.${C_NC}"
					fi
				fi

			else
				echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} Cannot deploy here, moving on.${C_NC}"
			fi

			echo -e "${C_CYAN}====================================================${C_NC}"

		done

		IFS="$OLDIFS"
	else
		echo -e "${C_CYAN_BD}None.${C_NC}"
	fi
else
	echo -e "${C_YELLOW_BD}!!!${C_YELLOW} Not deploying ${C_CYAN_BD}${HOST_DNS_NAME}${C_YELLOW} identity.${C_NC}"
fi

echo
echo -e "Host identity deployments completed for ${C_CYAN_BD}${HOST_DNS_NAME}${C_NC}: ${C_WHITE_BD}${DEPLOY_COUNT}${C_NC}"

IFS=" "
read -r -a ACTUAL_DEPLOY_SERVICES <<< "$(tr ' ' '\n' <<< "${DEPLOY_SERVICES[@]}" | sort -u | tr '\n' ' ')"
IFS="${OLDIFS}"

echo -e "Services to be restarted: ${C_WHITE_BD}${#ACTUAL_DEPLOY_SERVICES[@]}${C_NC}"

if [ ${#ACTUAL_DEPLOY_SERVICES[@]} -gt 0 ]
then
	echo
	for DS in ${ACTUAL_DEPLOY_SERVICES[@]}
	do
		echo -e "${C_MAGENTA}Restart service ${C_WHITE_BD}${DS}${C_MAGENTA}.${C_NC}"
	done

	echo
fi

exit

