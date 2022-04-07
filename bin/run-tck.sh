#! /bin/bash

set -e

fail() {
    echo "$1"
    p=true
    if [ -n "${2}" ]; then
        p=${2}
    fi
    if [ "${p}" == true ]; then
        printHelp
    fi
    exit 1
}

printArgHelp() {
    if [ -n "${3}" ]; then
        printf "%s, %-16s %s\n" "${1}" "${2}" "${3}"
    else
        printf "%-20s %s\n" "${1}" "${2}"
    fi
}

printHelp() {
    echo "Executes the Jakarta RESTful Web Services TCK. If the JBOSS_HOME environment is not set and no ZIP file is " \
         "passed in, then a WildFly server will be provisioned. The provisioning happens in the jakarta-rest-tck Maven project."
    echo ""
    echo "Arguments:"
    printArgHelp "-c" "--clean" "Cleans the work directory before running."
    printArgHelp "-f" "--file" "The WildFly ZIP file. This is not required if the JBOSS_HOME environment variable is set."
    printArgHelp "-s" "--skip" "Skips configuring your environment and running the Maven build."
    printArgHelp "-w" "--work" "The working directory for storing files. Defaults to $(readlink -m ./work)"
    printArgHelp "-h" "--help" "Displays the help text."
    echo ""
    echo "Any other arguments are passed to Maven."
    echo ""
    echo "Usage: ${0##*/} -Dmaven.repo.local=${HOME}/.m2/custom-repository"
    echo "       ${0##*/} -f wildfly.zip"
    echo "       ${0##*/} -c -w /tmp/rest-tck -f wildfly.zip"
}

pushDir() {
    pushd "${1}" || fail "Failed to change to directory ${1}." false
}

popDir() {
    popd || fail "Failed to reinstate previous directory." false
}

install() {
    filePrefix="${WORK_DIR}/${ARTIFACT_PREFIX}${REST_VERSION}";
    cmd=()
    cmd+=("org.apache.maven.plugins:maven-install-plugin:3.0.0-M1:install-file")
    cmd+=("-Dfile=${filePrefix}.jar")
    cmd+=("-DgroupId=jakarta.ws.rs")
    cmd+=("-DartifactId=jakarta-restful-ws-tck")
    cmd+=("-Dversion=${REST_VERSION}")
    cmd+=("-Dpackaging=jar")
    cmd+=("-Dsources=${filePrefix}-sources.jar")
    cmd+=("-DpomFile=${filePrefix}.pom")
    if [ -n "${1}" ]; then
        cmd+=("${1}")
    fi
    # shellcheck disable=SC2086
    mvn ${cmd[*]}
}

downloadMavenMaven() {
    download=false
    command -v "mvn" >/dev/null 2>&1 || download=true
    if [ ${download} == true ]; then
        pushDir "${WORK_DIR}"
        mvnVersion="3.8.5"
        echo "Downloading Maven ${mvnVersion}"
        curl -LO https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${mvnVersion}/apache-maven-${mvnVersion}-bin.zip
        unzip -o -q "apache-maven-${mvnVersion}-bin.zip"
        M2_HOME="${WORK_DIR}/apache-maven-${mvnVersion}"
        echo "M2_HOME=${M2_HOME}"
        export M2_HOME
        PATH="${M2_HOME}/bin:${PATH}"
        export PATH
        popDir
    fi
    command -v "mvn" >/dev/null 2>&1 || fail "Failed to install Maven" false
}

PATH="$(pwd)/bin:${PATH}"
export PATH

if [ -z "${TCK_URL}" ]; then
    TCK_URL="https://download.eclipse.org/jakartaee/restful-ws/3.1/jakarta-restful-ws-tck-3.1.0.zip"
fi

WORK_DIR="$(readlink -m ./work)"
PROJECT_DIR="$(readlink -m ./resteasy-tck-adapter)"

if [ -z "${REST_VERSION}" ]; then
    REST_VERSION="3.1.0"
fi
if [ -z "${ARTIFACT_PREFIX}" ]; then
    ARTIFACT_PREFIX="jakarta-restful-ws-tck-"
fi
file=""
args=""
localMavenRepo="${HOME}/.m2/repository"
clean=false
skip=false

while [ "$#" -gt 0 ]
do
    case "${1}" in
        -c|--clean)
            clean=true
            ;;
        -f|--file)
            if [ ! -f "${2}" ]; then
                fail "Argument ${2} is not a valid file"
            fi
            file="${2}"
            shift
            ;;
        -h|--help)
            printHelp
            exit 0
            ;;
        -s|--skip)
            skip=true
            ;;
        -w|--work-dir)
            WORK_DIR="${1}"
            shift
            ;;
        *)
            [[ "${1}" =~ ^-Dmaven\.repo\.local=.* ]] && localMavenRepo="${1#*=}"
            if [ -n "${args}" ]; then
                args="${args} ${1}"
            else
                args="${1}"
            fi
            ;;
    esac
    shift
done

if [ ${clean} == true ]; then
    if [ -d "${WORK_DIR}" ]; then
        echo "Removing work directory ${WORK_DIR}."
        rm -rf "${WORK_DIR}"
    fi
    echo "Cleaning your local Maven repository"
    find "${localMavenRepo}/jakarta/ws/rs" | grep "${REST_VERSION}" | grep -v "jbossorg" | xargs -I {} rm -rfv "{}"
fi

# Skip the rest of the process
if [ ${skip} == true ]; then
    exit 0
fi

if [ ! -d "${WORK_DIR}" ]; then
    mkdir "${WORK_DIR}"
fi

# Check to see if the TCK already exists
pushDir "${WORK_DIR}"
# Download Maven if required
downloadMavenMaven

# Download the TCK if necessary
if [ ! -f "${WORK_DIR}/jakarta-restful-ws-tck-3.1.0.zip" ]; then
    echo "Downloading the Jakarta RESTful Web Services TCK"
    curl -LO "${TCK_URL}"
    unzip -o -q "${WORK_DIR}/jakarta-restful-ws-tck-3.1.0.zip"
fi
popDir

# Check if a WildFly ZIP was provided
if [ -f "${file}" ]; then
    unzip -o -q -d "${WORK_DIR}" "${file}"
    JBOSS_HOME="${WORK_DIR}/wildfly"
    if [ -d "${JBOSS_HOME}" ]; then
        rm -rf "${JBOSS_HOME}"
    fi
    mv "${WORK_DIR}"/wildfly* "${WORK_DIR}/wildfly"
    export JBOSS_HOME
fi

# Validate the JBOSS_HOME if it was defined
if [ -n "${JBOSS_HOME}" ] && [ ! -d "${JBOSS_HOME}" ]; then
    fail "${JBOSS_HOME} is not a valid directory."
else
    if [ -n "${JBOSS_HOME}" ]; then
        echo "Using JBOSS_HOME=\"${JBOSS_HOME}\""
    else
        echo "A server will be provisioned."
    fi
fi

pushDir "${PROJECT_DIR}"
# Install the dependencies into the local maven repository
install "${args}"

if [ -z "${args}" ]; then
    echo "Running the Jakarta REST TCK"
    mvn clean verify
else
    echo "Running the Jakarta REST TCK with arguments: ${args}"
    # shellcheck disable=SC2086
    mvn clean verify ${args}
fi
popDir

