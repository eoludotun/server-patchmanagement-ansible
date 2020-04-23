#!/bin/bash
##############################################################################

source /absolute/path/to/variables.txt

# Functions ##################################################################
get_advisories() {
  yum updateinfo list all 2>/dev/null | awk '/RHSA-[0-9]{4}:[0-9]{4}/ {print $(NF-2)}' | sort -u
}

create_patch_set() {
  if [ ! -f "${BASELINE}" ]
  then
    get_advisories >"${BASELINE}" 2>/dev/null
    cp "${BASELINE}" "${CURRENT_PATCH_SET}" 2>/dev/null
  else
    if [ -f "${ADVISORIES}" ] && [ -s "${ADVISORIES}" ]
    then
      mv "${ADVISORIES}" "${BASELINE}"
    fi
    get_advisories >"${ADVISORIES}"
    comm -13 "${BASELINE}" "${ADVISORIES}" >"${CURRENT_PATCH_SET}"
  fi
}

create_vars() {
  if [ -f "${VARS}" ]
  then
    mv "${VARS}" "${VARS}.bak_`date +%Y-%m-%d`"
  fi
  ADVISORY_LIST=""
  while read NAME
  do
    if [[ -z $ADVISORY_LIST ]]
    then
      ADVISORY_LIST="${NAME}"
    else
      ADVISORY_LIST="${ADVISORY_LIST},${NAME}"
    fi
  done < "${CURRENT_PATCH_SET}"

  cat >"${VARS}" <<EOF
---
  Set_`date +%Y_%m`: ${ADVISORY_LIST}
  ###################################################
  rhsa_to_install: "{{ Set_`date +%Y_%m` }}"
EOF
}

