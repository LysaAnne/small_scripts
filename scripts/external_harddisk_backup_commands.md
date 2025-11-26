# NAME: external_harddisk_backup_commands.md
# DESC: Overview of commands used for backing up my external harddisks.


# Harddisk backup
## Windows
### Kopier fra D til E på Windows
``` robocopy D:\ E:\ /E /Z /MT:8 /R:1 /W:1 /V /TEE /LOG:copy-log.txt ```

OBS: Tjek at drev er korrekt

### Mirror D overpå E (sletter filer der ikke er de samme) på Windows
``` robocopy D:\ E:\ /MIR /Z /MT:8 /R:1 /W:1 /TEE /LOG:mirror-log.txt  ```

OBS: Tjek at drev er korrekt

### Robocopy forklaring
```
D:\ = kilde
E:\ = destination
/E = Kopierer alle mapper og undermapper. Inklusive tomme mapper
/Z = Genoptag kopiering hvis forbindelsen afbrydes (Restartable mode)
/MT:8 = Bruger 8 tråde (multithreaded kopi). 8 er optimalt ved HDD>>HDD. Mellem SSD brug 16
/R:1 = Retry 1 gang hvis en fil fejler (standard er 1 million!)
/W:1 = Vent 1 sekund mellem retries (standard er 30 sek)
/V = Verbose mode – viser ekstra detaljer i output
/TEE = Viser output i terminalen samtidig med at det skrives i logfilen
/LOG:copy-log.txt = Gemmer hele loggen i en fil der hedder copy-log.txt
/MIR = Mirror i stedet for copy
```

## Mac/Linux

### RAW-filer

Dry run:

``` rsync -avhn --progress "/Volumes/01 RAW/DONE (backup)/RAW/" "/Volumes/02.4_RAW/" ```

Alle i DONE: 

``` rsync -avh --progress "/Volumes/01 RAW/DONE (backup)/RAW/" "/Volumes/02.4_RAW/" | tee ~/rsync-RAW-log.txt ```

Kun BRYLLUP:

``` rsync -avh --progress "/Volumes/01 RAW/DONE (backup)/RAW/BRYLLUP/" "/Volumes/02.4_RAW/BRYLLUP/" | tee ~/rsync-BRYLLUP-log.txt ```

Kun PHOTOGRAPHY:

``` rsync -avh --progress "/Volumes/01 RAW/DONE (backup)/RAW/PHOTOGRAPHY/" "/Volumes/02.4_RAW/PHOTOGRAPHY/" | tee ~/rsync-PHOTOGRAPHY-log.txt ```

### JPG-filer
- Slet alle RAW
- Flyt alle mapper fra RAW over i JPG
- Lav nu rsync til 03.1 (JPG) harddisk

``` rsync -avh --progress "/Volumes/01 RAW/DONE (backup)/JPG/" "/Volumes/03.1 JPG/JPG (alle)/ | tee ~/rsync-JPG-log.txtSkal sorteres/" ```
- Sorter derefter filerne
- Lav derefter mirror mellem 03.1 og 03.2
⚠️ VIGTIGT ⚠️ Tjek at source og destination er korrekt
``` rsync -avh --delete --progress --info=stats2 "/Volumes/03.1_JPG/" "/Volumes/03.2 JPG/" | tee ~/rsync-mirror-log.txt``` 

### Rsync forklaring
```
-a = archive mode (bevar mappestruktur, kopier alle filer rekursivt mm.)
-v = Verbose
-h = Human readable — viser filstørrelser i MB/GB i stedet for bytes.
–delete = Kun til MIRROR. Alt der findes på destinationen, men ikke på source, bliver slettet.
–progress = Viser fremgang for hver fil under kopiering.
–info=stats2 = giver diverse logdata (overførelseshastighed, antal filer kopieret, data overført, tid mm.)
| tee ~/rsync-mirror-log.txt = output vises på skærm og skrives til log-fil
```
