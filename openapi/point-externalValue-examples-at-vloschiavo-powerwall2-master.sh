#!/bin/bash

branchToPointTo="${1:-master}"

temporaryDirectory=tmp-externalValues
externalValueFile=${temporaryDirectory}/externalValue-files.txt

rm -rf ${temporaryDirectory}
mkdir ${temporaryDirectory}

powerwall2MasterPath="vloschiavo/powerwall2/master"
powerwall2SpecifiedBranchPath="vloschiavo/powerwall2/${branchToPointTo}"

echo "finding examples that do not point to the master branch "${powerwall2MasterPath}""
grep -r externalValue paths/ | grep -v "${powerwall2MasterPath}" > ${externalValueFile}

while read -r line; do
    pathsFile="$(echo $line | cut -d':' -f1)"
    
    externalValue="$(echo ${line#*externalValue: })"
    gitHubUserAndBranch="$(echo ${externalValue#*githubusercontent.com/})"
    gitHubUserAndBranch="$(echo ${gitHubUserAndBranch%/samples*})"
    echo "pathsFile: '${pathsFile}', gitHubUserAndBranch: '${gitHubUserAndBranch}'"

    echo "replacing '${gitHubUserAndBranch}' with '${powerwall2SpecifiedBranchPath}'"
    sed -i "s/${gitHubUserAndBranch//\//\\/}/${powerwall2SpecifiedBranchPath//\//\\/}/g" ${pathsFile}

done < "$externalValueFile"