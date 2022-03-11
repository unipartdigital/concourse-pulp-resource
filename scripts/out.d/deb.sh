deb_files=`find $1 -name '*.deb'`
for deb in $deb_files; do
  if [[ `dpkg-deb -I $deb | grep 'Auto-Built-Package: debug-symbols'` ]]; then
    if [[ $UPLOAD_DEBUGS != "true" ]]; then
      echo "Not uploading debug symbols; set 'debug: true' to upload"
      continue
    fi
    package_name=$(dpkg-deb -I $deb | grep "^ Description: " | sed -e's/^ Description: debug symbols for //')
  else
    package_name=$(dpkg-deb -I $deb | grep "^ Package: " | sed -e's/^ Package: //')
  fi
  initial=${package_name:0:1}
  deb_name=$(echo $deb | rev | cut -d"/" -f1  | rev)
  relative_path="pool/${initial}/${package_name}/${deb_name}"
  file_count=$(http GET ${ENDPOINT}/pulp/api/v3/content/deb/packages/?relative_path=${relative_path} Authorization:"$BASIC_AUTH" | jq -r '.count')
  echo "Count: $file_count"
  if [[ $file_count -eq "0" ]]; then
    echo "Uploading $deb"
    export TASK_URL=$(http --form POST ${ENDPOINT}/pulp/api/v3/content/deb/packages/ file@"$deb" Authorization:"$BASIC_AUTH" --ignore-stdin | jq -r '.task')
    sleep 10
    export CONTENT_HREF=$(http GET ${ENDPOINT}${TASK_URL} Authorization:"$BASIC_AUTH" | jq -r '.created_resources | first')
  else
    CONTENT_HREF=$(http GET ${ENDPOINT}/pulp/api/v3/content/deb/packages/?relative_path=${relative_path} Authorization:"$BASIC_AUTH" | jq -r '.results[0].pulp_href')
  fi
  http POST ${ENDPOINT}${REPO_HREF}modify/ add_content_units:="[\"${CONTENT_HREF}\"]" Authorization:"$BASIC_AUTH" --ignore-stdin
  uploaded=1
done

if [[ -z "$uploaded" ]]; then
  echo "No files changed"
  exit 1
fi