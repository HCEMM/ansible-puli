### Issue with Keyboard Layout Change

When changing the keyboard layout in Guacamole, the new layout might not work as expected. This issue occurs because Guacamole does not automatically refresh or reconfigure the keyboard layout after it has been changed.

To resolve this issue, ensure that you manually reconnect the session or restart the Guacamole client to apply the new keyboard layout settings.

### Desktop icons

To create one, `.desktop` file on `/etc/skel/Desktop/` and `/home/*/Desktop/` should be symbolic link to a file on trusted folder. Trusted folders can be accessed at `$XDG_DATA_DIRS`.

Example of a `.desktop` for htop:
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=htop
Comment=System monitor
Exec=xfce4-terminal --command=htop      # -e is deprecated
Icon=utilities-system-monitor
Terminal=false
Categories=System;
StartupNotify=false
```

### SSH Key Setup for Guacamole Connections

For creating the SSH connection in Guacamole, you need to provide the private key used for authentication.

```
Navigate to the following directory in the repository:

guacamole/files/guacamole_key
guacamole/files/guacamole_key.pub

Copy the required private key file(s).

Paste the contents of the private key into the "Private Key" and ""Public Key"" fields in the Guacamole SSH connection setting.
```

### Access to guacamole_db
```
mysql -u root -p guacamole_db
exit;
```


