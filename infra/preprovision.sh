#!/bin/sh
set -e

# Generate and persist the DocumentDB admin password if not already set.
# This runs before 'azd provision' so the password is available in the
# azd environment for subsequent runs.

EXISTING=$(azd env get-value AZURE_DOCUMENTDB_ADMIN_PASSWORD 2>&1 || true)

# azd prints error text when the key doesn't exist, so treat that as empty
HAS_ERROR=$(echo "$EXISTING" | grep -i "error" || true)
if [ -z "$EXISTING" ] || [ -n "$HAS_ERROR" ]; then
  # Generate a 16-char random password with upper, lower, digit, and special chars
  PASSWORD=$(python3 -c "
import secrets, string
chars = string.ascii_letters + string.digits + '!@#%^&*'
while True:
    pw = ''.join(secrets.choice(chars) for _ in range(16))
    if (any(c.isupper() for c in pw) and any(c.islower() for c in pw)
        and any(c.isdigit() for c in pw) and any(c in '!@#%^&*' for c in pw)):
        print(pw)
        break
")
  azd env set AZURE_DOCUMENTDB_ADMIN_PASSWORD "$PASSWORD"
  echo "Generated and stored DocumentDB admin password in azd environment."
else
  echo "DocumentDB admin password already set in azd environment."
fi
