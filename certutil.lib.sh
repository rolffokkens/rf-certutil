cfgdir="/etc/rf-certutil"
_conf="${cfgdir}/rf-certutil.conf"
eval $(gawk '/^[A-Z]/ {print "cfg_" $0;}' ${_conf} | sed 's/[*]/\*/g')

cert_class_hyphen="${cfg_CERT_CLASS}${cfg_CERT_CLASS:+-}"
cert_class_space="${cfg_CERT_CLASS}${cfg_CERT_CLASS:+ }"
_file_pfx_hyphen="${cfg_CERT_FILE_PFX}${cfg_CERT_FILE_PFX:+-}"

file_pfx="${_file_pfx_hyphen}${cert_class_hyphen}"

libdir="/usr/share/rf-certutil"
vardir="/var/lib/rf-certutil"
logdir="/var/log/rf-certutil"
mgmtdir="${vardir}/mgmt"
certdir="${vardir}/certs"
keydir="${vardir}/keys"
cakey="${keydir}/${file_pfx}CA.key"
cacert="${certdir}/${file_pfx}CA.crt"
csrtmp=$(mktemp /tmp/csr-XXXXXX)

die ()
{
    local _fmt="$1"
    shift

    printf "${_fmt}\n" "$@" >&2;
    exit 1
}

log ()
{
    local _dt=$(date +%s)

    echo "${_dt}" "$@" >> "${logdir}/rf-certutil.log"
}

_gen_pwfile ()
{
    local _subject="$1"
    local _pwfile="certs/${_subject}.pwd"

    openssl rand -base64 32 > "${_pwfile}" || return 1

    echo "${_pwfile}"
}

_gen_csr ()
{
    local _subject="$1"
    local _keypfx="$2"
    local _csrfile="$3"

    VARDIR="${vardir}" openssl req \
        -config "${libdir}/openssl-req.cnf" \
        -new \
        -nodes \
        -keyout "${_keypfx}.key" \
        -out "${_csrfile}" \
        -subj "${cfg_CERT_SUBJECT_PFX}/CN=${_subject}"

    chmod 600 "${_keypfx}.key"
}

_gen_crt ()
{
    local _subname="$1"
    local _subject="$2"
    local _render_ext="$3"
    local _render_args="$4"
    local _certpfx="$5"
    local _csrfile="$6"
    local _sep_chain="$7"

    local _certtmp=$(mktemp /tmp/crt-XXXXXX)

    local _subcakey="${keydir}/${file_pfx}${_subname}-CA.key"
    local _subcacert="${certdir}/${file_pfx}${_subname}-CA.crt"
    local _subcachain="${certdir}/${file_pfx}${_subname}-CA.chain"

    VARDIR="${vardir}" openssl ca \
        -config "${libdir}/openssl-ca.cnf" \
        -extfile <(${_render_ext} ${_render_args}) \
        -extensions th_ext \
        -policy policy_anything \
        -batch \
        -notext \
        -days $(get_cert_days "${cfg_CERT_DAYS:-$((1*365))}") \
        -keyfile "${_subcakey}"  \
        -cert "${_subcacert}" \
        -out "${_certtmp}" \
        -infiles "${_csrfile}"

    if [[ ${_sep_chain} == 1 ]]
    then
        cp "${_certtmp}"         "${_certpfx}.crt"
        cp "${_subcachain}.full" "${_certpfx}.chain"
    else
        cat "${_certtmp}" "${_subcachain}.full" > "${_certpfx}.crt"
    fi

    rm "${_certtmp}"
}

do_cre_cert ()
{
    local _subname="$1"
    local _subject="$2"
    local _render_ext="$3"
    local _render_args="$4"
    local _keydir="$5"
    local _certdir="$6"
    local _certname="$7"
    local _sep_chain="$8"

    local _keypfx="${_keydir}/${file_pfx}${_certname}"
    local _certpfx="${_certdir}/${file_pfx}${_certname}"

    _gen_csr "${_subject}" "${_keypfx}" "${csrtmp}" || return 1
    _gen_crt "${_subname}" "${_subject}" "${_render_ext}" "${_render_args}" "${_certpfx}" "${csrtmp}" "${_sep_chain}" || return 1
}

_gen_ca_csr ()
{
    local _subname="$1"
    local _keypfx="$2"
    local _csrfile="$3"
    local _keyfile="${_keypfx}.key"
    local _keyarg

    _keyarg="-keyout"
    [[ -s ${_keyfile} ]] && _keyarg="-key"

    VARDIR="${vardir}" openssl req \
        -new \
        "${_keyarg}" "${_keypfx}.key" \
        -out "${csrtmp}" \
        -subj "${cfg_CERT_SUBJECT_PFX}/CN=${cfg_CA_CN} ${_subname} ${cert_class_space}CA"

    chmod 600 "${_keyfile}"
}

_gen_ca_crt ()
{
    local _subname="$1"
    local _render_ext="$2"
    local _render_args="$3"
    local _certpfx="$4"
    local _csrfile="$5"

    VARDIR="${vardir}" openssl ca \
        -config "${libdir}/openssl-ca.cnf" \
        -extfile <(${_render_ext} ${_render_args}) \
        -extensions th_ext \
        -policy policy_anything \
        -notext \
        -batch \
        -days $(get_cert_days "${cfg_CERT_SUBCA_DAYS:-$((5*365))}") \
        -keyfile "${cakey}" \
        -cert "${cacert}" \
        -out "${_certpfx}.crt" \
        -infiles "${_csrfile}"
}

do_cre_ca_cert ()
{
    local _subname="$1"
    local _render_ext="$2"
    local _render_args="$3"

    local _keypfx="${keydir}/${file_pfx}${_subname}-CA"
    local _certpfx="${certdir}/${file_pfx}${_subname}-CA"

    local _subcacert="${_certpfx}.crt"
    local _subcachain="${_certpfx}.chain"

    _gen_ca_csr "${_subname}" "${_keypfx}" "${csrtmp}"
    _gen_ca_crt "${_subname}" "${_render_ext}" "${_render_args}" "${_certpfx}" "${csrtmp}"

                        > "${_subcachain}"
    cat "${_subcacert}" > "${_subcachain}.full"
}

get_cert_days ()
{
    local _max="${cfg_CERT_MAXDAYS:-$((10*365))}"

    [[ ${_max} -ge $1 ]] && _max="$1"

    echo "${_max}"
}

cond_sudo ()
{
    [[ ${USER} == "root" ]] && die "Run $0 as normal user, not as root"

    if [[ ${USER} == "rf-certutil" ]]
    then
        [[ ${SUDO_USER} == "" ]] && die "Internal error, SUDO_USER"
        log "${SUDO_USER}" "$@"
        return 0
    fi

    exec sudo -u rf-certutil "$@"
}

render_ext_constraints ()
{
    local _ncons="$1"
    [[ ${_ncons} == "" ]] || _ncons="nameConstraints=${_ncons}"
cat << EOF
[ th_ext ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints=CA:TRUE
${_ncons}
EOF
}

