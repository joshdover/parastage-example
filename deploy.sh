#!/usr/bin/env bash

pr-messenger \
  --token $GH_TOKEN \
  --org $GH_ORG \
  --repo $CI_PROJECT_NAME \
  --sha $CI_COMMIT_SHA \
  --status_name "parastage/1_deploy" \
  --status_state "pending" \
  --status_description "Runover is deploying your branch" \
  --status_url "$CI_PROJECT_URL/pipelines/$CI_PIPELINE_ID"

export WEB_HOST="web.$CI_ENVIRONMENT_SLUG.review.mydomain.com"
export ADMIN_HOST="admin.$CI_ENVIRONMENT_SLUG.review.mydomain.com"

read -r -d '' PR_BLOCK << EOM
### Deployed to Parastage
Web: [Open](http://$WEB_HOST)
Admin: [Open](http://$ADMIN_HOST)
EOM

pr-messenger \
  --token $GH_TOKEN \
  --org $GH_ORG \
  --repo "$CI_PROJECT_NAME" \
  --branch "$CI_COMMIT_REF_NAME" \
  --comment "$PR_BLOCK"

KUBE_NAMESPACE=review

helm upgrade \
  --wait \
  --install \
  --reuse-values \
  --namespace $KUBE_NAMESPACE \
  --set apps.$CI_PROJECT_NAME.image=$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_NAME \
  --set info.reponame=$CI_PROJECT_NAME \
  --set info.pipeline_id=$CI_PIPELINE_ID \
  --set info.build_id=$CI_BUILD_ID \
  $CI_ENVIRONMENT_SLUG \
  /charts/parastage

pr-messenger \
  --token $GH_TOKEN \
  --org $GH_ORG \
  --repo $CI_PROJECT_NAME \
  --sha $CI_COMMIT_SHA \
  --status_name "parastage/1_deploy" \
  --status_state "success" \
  --status_description "Successfully deployed your branch" \
  --status_url "$CI_PROJECT_URL/pipelines/$CI_PIPELINE_ID"
