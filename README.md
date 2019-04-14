# El Segmentador

Tool to automate corporate networks segmentation test

![](https://img.shields.io/github/license/yozgarcia/el_segmentador.svg?style=plastic) ![](https://img.shields.io/github/last-commit/yozgarcia/el_segmentador.svg) ![](https://img.shields.io/badge/nmap-%3E%3D%207.0-green.svg)

## Features
- Create a file structure to store the results in an orderly manner
- Scans and analyzes live machines in different network segments, using four different Ping Scan Methods
- Performs a deeper scan in live machines, looking for enumerate the versions of the services and possible vulnerabilities, both for TCP and UDP ports
- Record the total usage time of the script
- Compatible with all nmap versions above the 7.0

## Issues
- Some people may need to run with sudo permissions for the full nmap operation

### Installation

- Clone or [Download](https://github.com/yozgarcia/el_segmentador/archive/master.zip) the master branch from git

```bash
git clone https://github.com/yozgarcia/el_segmentador.git
```
```bash
wget -o https://github.com/yozgarcia/el_segmentador/archive/master.zip
```

### Usage
- Need to establish execution permission with chmod command for "el_segmentador.sh" and execute
- The script will ask:
 - The output folder of the resulting information
 - The network interface 
 - The file with the work scope

```bash
cd el_segmentador
chmod +x el_segmentador.sh
./el_segmentador.sh
```

### Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.