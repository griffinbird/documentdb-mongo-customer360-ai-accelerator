#!/bin/sh
set -e

echo "============================================"
echo "  Post-provisioning: Generating .env"
echo "============================================"

# The azd environment variables are available as env vars after provisioning
# Build the connection string with credentials embedded
ADMIN_USER="${AZURE_DOCUMENTDB_ADMIN_USERNAME:-docdbadmin}"

# Get the password from azd env
ADMIN_PASSWORD=$(azd env get-value AZURE_DOCUMENTDB_ADMIN_PASSWORD 2>/dev/null || echo "")

# Get the base connection string from azd outputs
CONN_STRING=$(azd env get-value DOCUMENTDB_CONN_STRING 2>/dev/null || echo "")

# Replace the <user>:<password> placeholder in the connection string if needed
if [ -n "$CONN_STRING" ] && [ -n "$ADMIN_PASSWORD" ]; then
    # URL-encode the password to handle special characters (@, !, #, etc.)
    ENCODED_PASSWORD=$(python3 -c "from urllib.parse import quote_plus; print(quote_plus('$ADMIN_PASSWORD'))" 2>/dev/null || echo "$ADMIN_PASSWORD")
    # DocumentDB connection strings from Bicep output: mongodb+srv://<host>/?<params>
    # We need to inject user:password@ before the host
    # First, strip any existing credentials (handles both fresh and re-run cases)
    CONN_STRING=$(echo "$CONN_STRING" | sed -E "s|mongodb\+srv://([^@]*@)?|mongodb+srv://${ADMIN_USER}:${ENCODED_PASSWORD}@|" 2>/dev/null || echo "$CONN_STRING")
fi

OPENAI_ENDPOINT=$(azd env get-value OPENAI_API_ENDPOINT 2>/dev/null || echo "")
OPENAI_EMBEDDINGS_DEPLOYMENT=$(azd env get-value OPENAI_EMBEDDINGS_DEPLOYMENT 2>/dev/null || echo "")
OPENAI_EMBEDDINGS_MODEL_NAME=$(azd env get-value OPENAI_EMBEDDINGS_MODEL_NAME 2>/dev/null || echo "")
OPENAI_COMPLETIONS_DEPLOYMENT=$(azd env get-value OPENAI_COMPLETIONS_DEPLOYMENT 2>/dev/null || echo "")
OPENAI_API_VERSION=$(azd env get-value OPENAI_API_VERSION 2>/dev/null || echo "2024-10-21")
OPENAI_API_TYPE=$(azd env get-value OPENAI_API_TYPE 2>/dev/null || echo "azure")

# Write the .env.run file
cat > .env <<EOF
DOCUMENTDB_CONN_STRING = ${CONN_STRING}
OPENAI_API_ENDPOINT = ${OPENAI_ENDPOINT}
OPENAI_API_KEY = USES_MANAGED_IDENTITY
OPENAI_API_TYPE = "${OPENAI_API_TYPE}"
OPENAI_API_VERSION = ${OPENAI_API_VERSION}
OPENAI_EMBEDDINGS_DEPLOYMENT = ${OPENAI_EMBEDDINGS_DEPLOYMENT}
OPENAI_EMBEDDINGS_MODEL_NAME = ${OPENAI_EMBEDDINGS_MODEL_NAME}
OPENAI_COMPLETIONS_DEPLOYMENT = ${OPENAI_COMPLETIONS_DEPLOYMENT}
EOF

echo ""
echo ".env file created successfully!"
echo ""
echo "NOTE: The notebook uses DefaultAzureCredential for OpenAI authentication."
echo "      Make sure you are logged in with 'az login' and have the"
echo "      'Cognitive Services OpenAI User' role on the OpenAI resource."
echo ""
echo "To use the .env file, update config.env or set:"
echo "  env_name = '.env'"
echo "in the notebook."
echo "============================================"
