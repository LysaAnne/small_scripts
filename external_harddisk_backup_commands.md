# Harddisk backup
## Windows
### Kopier fra D til E på Windows
``` robocopy D:\ E:\ /E /Z /MT:8 /R:1 /W:1 /V /TEE /LOG:copy-log.txt ```

OBS: Tjek at drev er korrekt

### Mirror D overpå E (sletter filer der ikke er de samme) på Windows
``` robocopy D:\ E:\ /MIR /Z /MT:8 /R:1 /W:1 /TEE /LOG:mirror-log.txt  ```

OBS: Tjek at drev er korrekt

### Robocopy forklaring
``` D:\ = kilde
E:\ = destination
/E = Kopierer alle mapper og undermapper. Inklusive tomme mapper
/Z = Genoptag kopiering hvis forbindelsen afbrydes (Restartable mode)
/MT:8 = Bruger 8 tråde (multithreaded kopi). 8 er optimalt ved HDD>>HDD. Mellem SSD brug 16
/R:1 = Retry 1 gang hvis en fil fejler (standard er 1 million!)
/W:1 = Vent 1 sekund mellem retries (standard er 30 sek)
/V = Verbose mode – viser ekstra detaljer i output
/TEE = Viser output i terminalen samtidig med at det skrives i logfilen
/LOG:copy-log.txt = Gemmer hele loggen i en fil der hedder copy-log.txt
/MIR = Mirror i stedet for copy ```

## Mac/Linux
