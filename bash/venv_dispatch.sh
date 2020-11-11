# Check that this is a Git repo
GIT_DIR=`git rev-parse --git-dir 2> /dev/null`
# Find the repo root and check for virtualenv name override
GIT_DIR=`\cd $GIT_DIR; pwd`
PROJECT_ROOT=`dirname "$GIT_DIR"`
ENV_NAME=`basename "$PROJECT_ROOT"`
if [ -f "$PROJECT_ROOT/.venv" ]; then
  ENV_NAME=`cat "$PROJECT_ROOT/.venv"`
fi
# Activate the environment only if it is not already active
if [ -e "$WORKON_HOME/$ENV_NAME/bin/python" ]; then
  echo "$WORKON_HOME/$ENV_NAME/bin/python"
else
  echo "python"
fi


