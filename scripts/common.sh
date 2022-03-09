pre_flight() {
  package_type="$(jq -r '.source.type // ""' < $1)"
  username="$(jq -r '.source.username // ""' < $1)"
  password="$(jq -r '.source.password // ""' < $1)"
  endpoint="$(jq -r '.source.endpoint // ""' < $1)"
  repository="$(jq -r '.source.repository // ""' < $1)"

  version="$(jq -r '.version.number // ""' < $1)"

  case ${package_type} in
    deb)
      export REPO_TYPE=deb/apt
      ;;
    *)
      echo "Unsupported package type ${package_type}"
      exit 1
      ;;
  esac

  if [[ -z "${username}" ]]; then
    echo "username must be supplied for auth"
    exit 1
  fi

  if [[ -z "${password}" ]]; then
    echo "password must be supplied for auth"
    exit 1
  fi

  if [[ -z "${endpoint}" ]]; then
    echo "endpoint must be supplied"
    exit 1
  fi

  if [[ -z "${repository}" ]]; then
    echo "repository must be supplied"
    exit 1
  fi

  export PACKAGE_TYPE=${package_type}
  export BASIC_AUTH="Basic `echo -n ${username}:${password} | base64`"
  export ENDPOINT=${endpoint}
  export REPO_NAME=${repository}

  if [[ -n "${version}" ]]; then
    export REPO_VERSION=${version}
    export INPUT_VERSION="$(jq -r '{version}' < $1)"
  else
    export REPO_VERSION=-1
    export REPO_VERSION='{"version":{"number":"-1"}}'
  fi
}