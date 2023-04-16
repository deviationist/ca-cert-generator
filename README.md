# CA Cert Generator
This is a simple bash script that uses OpenSSL to generate a CA ceritifcate along with one or more corresponding server certificates. Very handy if you wanna create valid HTTPS-connections on your LAN.

Based off [this article](https://carpie.net/articles/tls-certificates-for-local-area-networks).

## Usage
Command:
```./generate.sh [DOMAINS] [CM_NAME] [PASS] [VALID_FOR_DAYS](optional)```

`DOMAINS` can be either one domain or multiple separated by comma.
`VALID_FOR_DAYS` is set to 10 years (3650 days) by default.

Example usage:<br>
```./generate.sh "your-domain.local,*.your-domain.local" "YourCM" "your-super-secret-password" 397```

The files will be placed in `output/[CM_NAME]`, in this case `output/YourCM`.

If you get permission errors then run `chmod +x generate.sh`.

You can then use `[DOMAIN].crt` and "[DOMAIN].key" in your webserver-config to establish valid HTTPS-connection. In this case the filenames would be `*.your-domain.local.crt` and `*.your-domain.local.key`.

Be sure to store the password if you want to add additional server certificates in the future.

The generate additional server certificates just run the same command again and the 

Note: It's recommended to run `history -c` afterwards since the shell history will reveal your CA password.

Enjoy!