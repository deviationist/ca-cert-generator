# CA Cert Generator
This is a simple bash script that uses OpenSSL to generate a CA ceritifcate along with one or more corresponding server certificates. Very handy if you wanna create valid HTTPS-connections on your LAN.

## Usage
```./generate.sh [DOMAIN] [CM_NAME] [PASS] [VALID_FOR_DAYS]```

Example:<br>
```./generate.sh "*.your-domain.local" "YourCM" "your-super-secret-password" 397```

The files will be placed in "output/[CM_NAME]", in this case "output/YourCM".

You can then use "[DOMAIN].crt" and "[DOMAIN].key" in your webserver-config to establish valid HTTPS-connection.

Note: It's recommended to run `history -c` afterwards since the shell history will reveal your CA password.