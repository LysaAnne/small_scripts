# Harddisk backup
## Windows
### Kopier fra D til E på Windows
``` robocopy D:\ E:\ /E /Z /MT:8 /R:1 /W:1 /V /TEE /LOG:copy-log.txt ```

### Mirror D overpå E (sletter filer der ikke er de samme) på Windows
``` robocopy D:\ E:\ /MIR /Z /MT:8 /R:1 /W:1 /LOG:mirror-log.txt /TEE ```
