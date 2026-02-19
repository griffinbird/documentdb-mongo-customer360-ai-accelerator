# What Is It?
The Customer 360 AI Solution Accelerator is a ready‑to‑deploy reference implementation that demonstrates how to build a modern, intelligent customer data platform using Azure DocumentDB (with MongoDB compatibility).

# Who is it for?

- Banks and financial institutions modernizing legacy systems
- Teams migrating from on-prem MongoDB or MongoDB Atlas
- Architects exploring AI, RAG, and real-time analytics use cases

# What’s Included?

- Sample Customer 360 schema and data
- Aggregation pipelines
- Graph lookups
- Power BI like dashboards for real-time insights
- Vector search + RAG integration with Azure OpenAI

# Why Use This Accelerator?

- Try before you build: Explore DocumentDB capabilities in a sandboxed Azure environment
- Accelerate time-to-value: Use pre-built components to jumpstart your implementation
- Showcase to stakeholders: Demonstrate real-world use cases like segmentation, fraud detection, and intelligent assistants

# Setup Accelerator

## Prerequisites

- An active **Azure subscription**
- [Azure Developer CLI (`azd`)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) installed
- [Azure CLI (`az`)](https://learn.microsoft.com/cli/azure/install-azure-cli) installed
- Python 3.9+

## Provision Azure Resources

The accelerator uses `azd` to provision an **Azure DocumentDB (MongoDB vCore)** cluster and an **Azure OpenAI** account with embeddings and completions deployments.

```bash
# Log in to Azure
azd auth login

# Initialize and provision all resources
azd up
```

You will be prompted for:

| Prompt | Description | Default |
|---|---|---|
| Environment name | Used as a prefix for all resources | — |
| Azure location | Region for resource deployment | — |
| DocumentDB admin password | Password for the DocumentDB cluster (must meet complexity requirements) | — |

> **Tip:** You can pre-set the password before provisioning with `azd env set AZURE_DOCUMENTDB_ADMIN_PASSWORD <your-password>` to skip the interactive prompt.

### What gets deployed

| Resource | Description |
|---|---|
| **Azure DocumentDB** | M30 cluster with vector search support (HNSW, DiskANN) |
| **Azure OpenAI** | `text-embedding-ada-002` embeddings + `gpt-4.1` completions deployments |

### Optional overrides

You can customize deployment parameters before running `azd up`:

```bash
azd env set AZURE_DOCUMENTDB_CLUSTER_TIER M10
azd env set AZURE_OPENAI_LOCATION australiasoutheast
azd env set AZURE_OPENAI_COMPLETIONS_DEPLOYMENT gpt-4.1
```

## Install Python Dependencies

After provisioning, install the required Python packages:

```bash
pip install -r requirements.txt
```

## Configure the Notebook

After provisioning, a `.env` file is automatically generated with the connection details. Update the notebook to use it:

```python
env_name = ".env"
```

The `.env` file contains:

```
DOCUMENTDB_CONN_STRING = <your-connection-string>
OPENAI_API_ENDPOINT = <your-openai-endpoint>
OPENAI_API_KEY = USES_MANAGED_IDENTITY
OPENAI_API_TYPE = "azure"
OPENAI_API_VERSION = 2024-10-21
OPENAI_EMBEDDINGS_DEPLOYMENT = text-embedding-ada-002
OPENAI_EMBEDDINGS_MODEL_NAME = text-embedding-ada-002
OPENAI_COMPLETIONS_DEPLOYMENT = gpt-4.1
```

> **Note:** The notebook uses `DefaultAzureCredential` for OpenAI authentication. Ensure your identity has the **Cognitive Services OpenAI User** role on the OpenAI resource (see next step).

## Assign OpenAI Role

The notebook authenticates to Azure OpenAI using `DefaultAzureCredential`, which relies on your Azure CLI login. For this to work, your identity needs the **Cognitive Services OpenAI User** role on the deployed OpenAI resource.

A helper script is provided to automate this:

```bash
# 1. Make sure you are logged in to Azure CLI
az login --tenant <your-tenant>.onmicrosoft.com --use-device-code

# 2. Run the role assignment script
./infra/assign-openai-role.sh
```

The script will:
1. Detect your signed-in user identity
2. Find the OpenAI resource in your azd resource group
3. Assign the **Cognitive Services OpenAI User** role (or confirm it's already assigned)

You can also pass the resource group explicitly:

```bash
./infra/assign-openai-role.sh <resource-group-name>
```

## Tear Down

To remove all provisioned resources:

```bash
azd down --purge
```