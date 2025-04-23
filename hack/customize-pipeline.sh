branch="main"
for file in "$@"
do
    action=$(basename `expr "$file" : '.*\(pu.*\.yaml\)'` .yaml | tr - _)
    component="${file%-pu*.yaml}"
    dockerfile=$(yq '.spec.params[] | select(.name == "dockerfile").value' "$file")
    export trigger="event == \"$action\" && target_branch == \"$branch\" &&
        (\"$component-pull-request.yaml\".pathChanged() ||
        \"$component-push.yaml\".pathChanged() ||
        \"catalog\".pathChanged() ||
        \"$dockerfile\".pathChanged())"
    echo "Processing file $file"
    yq -i '.metadata.annotations += {"pipelinesascode.tekton.dev/on-cel-expression": strenv(trigger)}' "$file"
    yq -i '(.spec.params[] | select(.name == "build-platforms").value | select(length == 1)) += ["linux/arm64","linux/ppc64le","linux/s390x"]' "$file"
    yq -i 'with(.spec.params; select(all_c(.name != "build-source-image")) | . += [{"name": "build-source-image", "value": "true"}])' "$file"
done
