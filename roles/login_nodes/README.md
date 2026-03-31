This role is lowkey becoming the most important of the system.

It builds the environment for users. Most of the user experience outside of the workload manager comes from here.

### Applying Limits
After deploying this role, the new systemd slice limits will not fully apply to existing user sessions. To ensure the limits take effect, one of the following actions is required:

loginctl terminate-user