#!/usr/bin/env bash

if [ $SKIP_REDEPLOY ]; then exit 0; fi

pr-messenger \
	--token $GH_TOKEN \
	--org $GH_ORG \
	--repo $CI_PROJECT_NAME \
	--sha $CI_COMMIT_SHA \
	--status_name "parastage/0_build" \
	--status_state "pending" \
	--status_description "Building your branch" \
	--status_url "$CI_PROJECT_URL/pipelines/$CI_PIPELINE_ID"

pr-messenger \
	--token $GH_TOKEN \
	--org $GH_ORG \
	--repo $CI_PROJECT_NAME \
	--sha $CI_COMMIT_SHA \
	--status_name "parastage/1_deploy" \
	--status_state "pending" \
	--status_description "Waiting for you branch to be built" \
	--status_url "$CI_PROJECT_URL/pipelines/$CI_PIPELINE_ID"

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

export DEPLOY_ROOT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

source "$DEPLOY_ROOT_DIR/src/common.bash"

echo "Checking docker engine..."

if ! docker info ; then
	echo "Cannot connect to docker engine to build images."
fi

docker rm -f "$CI_CONTAINER_NAME" &>/dev/null || true

echo "Building application..."

echo "Building Dockerfile-based application..."
# Build Dockerfile
docker build --build-arg RELEASE_TAG="$CI_COMMIT_REF_NAME" -t "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_NAME" .

echo "Logging to GitLab Container Registry with CI credentials..."
docker login -u $CI_REGISTRY_USER -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
echo ""

echo "Pushing to GitLab Container Registry..."
docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_NAME"

pr-messenger \
  --token $GH_TOKEN \
  --org $GH_ORG \
  --repo $CI_PROJECT_NAME \
  --sha $CI_COMMIT_SHA \
  --status_name "parastage/0_build" \
  --status_state "success" \
  --status_description "Runover successfully built your branch" \
  --status_url "$CI_PROJECT_URL/pipelines/$CI_PIPELINE_ID"
