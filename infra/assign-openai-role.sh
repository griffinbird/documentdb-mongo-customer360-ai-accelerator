#!/bin/bash
set -e

echo "============================================"
echo "  Assign Cognitive Services OpenAI User Role"
echo "============================================"

# Get resource group from azd environment or use argument
RESOURCE_GROUP="${1:-$(azd env get-value AZURE_RESOURCE_GROUP 2>/dev/null || echo "")}"

if [ -z "$RESOURCE_GROUP" ]; then
    echo "ERROR: Could not determine resource group."
    echo "Usage: ./infra/assign-openai-role.sh <resource-group-name>"
    echo "   or: run 'azd env get-value AZURE_RESOURCE_GROUP' to check."
    exit 1
fi

echo "Resource group: $RESOURCE_GROUP"

# Get the signed-in user's object ID
echo "Getting signed-in user..."
USER_ID=$(az ad signed-in-user show --query id -o tsv)
USER_NAME=$(az ad signed-in-user show --query userPrincipalName -o tsv)
echo "User: $USER_NAME ($USER_ID)"

# Get the OpenAI resource ID
echo "Finding OpenAI resource in resource group '$RESOURCE_GROUP'..."
OPENAI_ID=$(az cognitiveservices account list \
    --resource-group "$RESOURCE_GROUP" \
    --query "[?kind=='OpenAI'].id | [0]" -o tsv)

if [ -z "$OPENAI_ID" ]; then
    echo "ERROR: No OpenAI resource found in resource group '$RESOURCE_GROUP'."
    exit 1
fi

OPENAI_NAME=$(basename "$OPENAI_ID")
echo "OpenAI resource: $OPENAI_NAME"

# Check if role is already assigned
EXISTING=$(az role assignment list \
    --assignee "$USER_ID" \
    --role "Cognitive Services OpenAI User" \
    --scope "$OPENAI_ID" \
    --query "length(@)" -o tsv 2>/dev/null || echo "0")

if [ "$EXISTING" -gt 0 ]; then
    echo ""
    echo "Role 'Cognitive Services OpenAI User' is already assigned to $USER_NAME."
    echo "No changes needed."
else
    echo "Assigning 'Cognitive Services OpenAI User' role..."
    az role assignment create \
        --assignee "$USER_ID" \
        --role "Cognitive Services OpenAI User" \
        --scope "$OPENAI_ID" \
        --output none
    echo ""
    echo "Role assigned successfully!"
fi

echo ""
echo "You can now use DefaultAzureCredential in the notebook."
echo "============================================"
