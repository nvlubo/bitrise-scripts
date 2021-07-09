#!/usr/bin/env bash

set -e

set -x

#
# Input Variables:
#   BITRISE_GIT_TAG in format x.x.x.x
#

if [ -z "$BITRISE_GIT_TAG" ]; then
    echo "required input variable BITRISE_GIT_TAG is not defined"
    exit 1
fi

if [[ ! "$BITRISE_GIT_TAG" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "BITRISE_GIT_TAG doesn't match the pattern x.x.x.x"
    exit 2
fi

majorVersion=$(echo "$BITRISE_GIT_TAG" | cut -d . -f 1)
minorVersion=$(echo "$BITRISE_GIT_TAG" | cut -d . -f 2)
patchVersion=$(echo "$BITRISE_GIT_TAG" | cut -d . -f 3)


#
# find out what is the ui-sdk version used in the version tagged by BITRISE_GIT_TAG
#
uiSdkVersion=$(cat app/src/main/assets/dependencies.txt | grep "ai.nativevoice.ui:sdk:" | cut -d ">" -f 2 | sed -e 's/^[[:space:]]*//')

#
# replace the variable UI_SDK_VERSION_PROD in gradle.properties
#
GRADLE_PROP_FILE=gradle.properties
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^UI_SDK_VERSION_PROD=.*$/UI_SDK_VERSION_PROD=$uiSdkVersion/g" $GRADLE_PROP_FILE
else
    sed -i "s/^UI_SDK_VERSION_PROD=.*$/UI_SDK_VERSION_PROD=$uiSdkVersion/g" $GRADLE_PROP_FILE
fi

# Compute the new prod version
patchVersion=$((patchVersion+1))
prodVersion="$majorVersion.$minorVersion.$patchVersion-RELEASE"
upstreamBranch="support/${majorVersion}.${minorVersion}"

# create a new branch for committing changes
git checkout -b $prodVersion $BITRISE_GIT_TAG

# Commit the change 
git add $GRADLE_PROP_FILE
COMMIT_MSG=$(cat <<EOF
chore: prepare for playstore release
EOF
)
git commit -m "$COMMIT_MSG"
#git push --set-upstream origin $upstreamBranch

#
# Tag it for release
# 
git tag "$prodVersion"
git push origin :"$prodVersion"
