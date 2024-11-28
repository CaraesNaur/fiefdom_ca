#!/bin/bash

# Go to script location
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")"

source includes/common.sh

# Declare directory base names for CA chain members
CA_BASE_PATH=$(pwd)

OLDIFS="$IFS"
NEWIFS=$'\n'

declare -A DEPLOYMENTS

CA_DEPLOYMENTS_FILE="${CA_BASE_PATH}/${CA_DEPLOYMENTS_FILE_BARE}"
ADD_MORE=true
ADDDEPDEF=y

DEPS_LIST=()
DEP_PATHS=()

DC=0

echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"
echo -e "${C_WHITE_BLUE_BD}# Certificate Deployment Targets                   #${C_NC}"
echo -e "${C_WHITE_BLUE_BD}####################################################${C_NC}"

if [[ ! -f ${CA_DEPLOYMENTS_FILE} ]]
then
	echo -e "${C_WHITE_YELLOW_BD}!!!${C_YELLOW_BD} Deployments file ${C_GREEN_BD}${CA_DEPLOYMENTS_FILE}${C_YELLOW_BD} does not exist!${C_NC}"
	echo -e "${C_GREEN}Creating deployments file...${C_NC}"
	touch ${CA_DEPLOYMENTS_FILE}
else
	echo -e "${C_GREEN}Deployments file found: ${C_GREEN_BD}${CA_DEPLOYMENTS_FILE}${C_NC}"

fi

echo
echo "This tool allows host identity deployment locations to be configured."
echo
echo -e "If no deployments are configured, other scripts here cannot automatically"
echo "deploy host identity files."
echo

CA_DEP_SECS=$(./iniget ${CA_DEPLOYMENTS_FILE} -l)

CA_DEP_SECS_COUNT=$(echo -n "${CA_DEP_SECS}" |grep -Pc '^')

echo -e "Current deployments: ${C_WHITE_BD}${CA_DEP_SECS_COUNT}${C_NC}"
echo

if [[ ${CA_DEP_SECS_COUNT} -gt 0 ]]
then
	IFS="${NEWIFS}"

	for DST in ${CA_DEP_SECS}
	do
		DEP_PATH=$(./iniget ${CA_DEPLOYMENTS_FILE} "${DST}" path)
		DEP_SVC=$(./iniget ${CA_DEPLOYMENTS_FILE} "${DST}" service)

		IFS="${OLDIFS}"
		DEPLOYMENTS["${DST//\"/\\\"}"]="${DEP_PATH};${DEP_SERVICE}"
		IFS="${NEWIFS}"

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
		else
			DEP_PATH_STAT="${C_GREEN_BD}${DEP_PATH}${C_NC}"
			DEP_PATH_OK=true
			DEP_PATHS+=("${DEP_PATH}")
		fi

		if [[ -z "${DEP_SVC}" ]]
		then
			DEP_SVC_STAT="${C_RED}No service set${C_NC}"
		elif [ $(systemctl list-unit-files ${DEP_SVC}.service &>/dev/null) ]
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

		echo -e "   ${C_CYAN}To: ${DEP_PATH_STAT}"
		echo -e "   ${C_CYAN}For: ${DEP_SVC_STAT}"
		echo
	done

	IFS="${OLDIFS}"
else
	echo -e "${C_CYAN_BD}None.${C_NC}"
fi

echo

while [[ "${ADD_MORE}" == true ]]
do
	read -e -p "$( echo -e "Add deployment? [${C_GREEN_BD}Y${C_NC}/n] ")" ADDDEP
	ADDDEP="${ADDDEP:-${ADDDEPDEF}}"
	ADDDEP="${ADDDEP,,}"

IFS="${NEWIFS}"
for K in ${!DEPLOYMENTS[@]}
do
	echo "${K}: ${DEPLOYMENTS[${K}]}"
done
IFS="${OLDIFS}"

	if [[ "${ADDDEP}" != "${ADDDEPDEF}" ]]
	then
		ADD_MORE=false

		echo -e "${C_YELLOW}Stopping.${C_NC}"

		break
	else
		DEP_OK=true

		echo
		echo -e "${C_GREEN}Adding new host deployment ...${C_NC}"

		for FIELD in label path service
		do
			FIELD_OK=false

			while [[ "${FIELD_OK}" != true ]] && [[ ${DEP_OK} == true ]]
			do
				read -e -p "$( echo -e "Deployment ${C_CYAN}${FIELD^}${C_NC}: ")" DEPFIELD

				if [[ -z ${DEPFIELD} ]]
				then
					echo -e "${C_YELLOW}No value given, starting again.${C_NC}"
					echo
					#ADD_MORE=false
					DEP_OK=false

					break 2
				else
					echo -e "Got ${C_CYAN}${FIELD^} '${C_WHITE_BD}${DEPFIELD}${C_CYAN}'${C_NC}"

					case ${FIELD} in
						label)
							if [[ ! -n "${DEPLOYMENTS["${DEPFIELD}"]}" ]]
							then
								FIELD_OK=true
							else
								echo -e "${C_RED}Deployment label '${C_WHITE_BD}${DEPFIELD}${C_RED}' already exists!${C_NC}"
							fi

							DEP_LABEL="${DEPFIELD}";;
						path)
							if [[ -d "${DEPFIELD}" ]]
							then
								if [[ " ${DEP_PATHS[*]} " =~ " ${DEPFIELD} " ]]
								then
									echo -e "${C_RED}Deployment path ${C_RED_BD}${DEPFIELD}${C_RED} already used!${C_NC}"
								else
									FIELD_OK=true
								fi
							else
								echo -e "${C_RED}Deployment path ${C_RED_BD}${DEPFIELD}${C_RED} does not exist!${C_NC}"
							fi

							DEP_PATH="${DEPFIELD}";;
						service)
							systemctl list-unit-files ${DEPFIELD}.service &>/dev/null

							if [[ $? -eq 0 ]]
							then
								FIELD_OK=true
							else
								echo -e "${C_RED}Deployment service '${C_WHITE_BD}${DEPFIELD}${C_RED}' not installed!${C_NC}"
							fi

							DEP_SERVICE="${DEPFIELD}";;
					esac
				fi
			done
		done

		if [[ "${DEP_OK}" == true ]]
		then
			cat <<EOT >> ${CA_DEPLOYMENTS_FILE}
[${DEP_LABEL}]
path = ${DEP_PATH}
service = ${DEP_SERVICE}

EOT
			DEPLOYMENTS["${DEP_LABEL//\"/\\\"}"]="${DEP_PATH};${DEP_SERVICE}"
			((DC++))

			echo -e "${C_GREEN}Added deployment ${C_WHITE_BD}${DEP_LABEL}${C_GREEN}.${C_NC}"
			echo
		fi
	fi
done

echo

IFS="${OLDIFS}"

echo -e "${C_GREEN}Deployments added: ${C_WHITE_BD}${DC}${C_GREEN} (total: ${C_WHITE_BD}${#DEPLOYMENTS[@]}${C_GREEN})${C_NC}"
