export JAVA_PROGRAM_ARGS=`echo "$@"`
FILE_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
jbang ${FILE_PATH}/report/Report.java ${JAVA_PROGRAM_ARGS}
