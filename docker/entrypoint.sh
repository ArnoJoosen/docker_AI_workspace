#!/bin/bash

# Get the username from environment or default to 'user'
USERNAME=${USERNAME:-user}
export USERNAME
export ENV_USERNAME=${USERNAME}

# Ensure proper ownership of user directories at startup
# This handles cases where volumes might be mounted with incorrect ownership
if id "$USERNAME" &>/dev/null; then
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/workspace /home/${USERNAME}/.venv /home/${USERNAME}/.ssh 2>/dev/null || true
else
    echo "Warning: User $USERNAME does not exist, skipping chown operations"
fi

# Create workspace directory if it doesn't exist
mkdir -p /home/${USERNAME}/workspace
if id "$USERNAME" &>/dev/null; then
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/workspace
fi

# Execute the original command
exec "$@"
