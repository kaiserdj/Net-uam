<h1 align="center">NET UAM</h1> 

This is a project to take advantage of an overpowered machine, and be able to mine in multiple instances on the [Utopia P2P network.](https://u.is/es)

Download
-------
In order to start it is necessary to have docker installed on the machine.
https://docs.docker.com/desktop/install/linux-install/

Clone this project:

```bash
> git clone https://github.com/kaiserdj/net-uam.git
> cd net-uam
```
### Usage
-------
##### Setting
Edit the config file, in which you must add the personal mining key of the Utopia account you want to mine.
Config file values:
| Name | Description | Value(example) |
|--|--|--|
| NUM_INSTANCES | Number of instances that will be opened for mining.<br>Take into account the requirements to mine in an instance:<br>&nbsp;&nbsp;- A minimum of 4 CPU Cores<br>&nbsp;&nbsp;- A minimum of 4 GB Ram<br>&nbsp;&nbsp;- Public IP<br>&nbsp;&nbsp;- High Speed Internet | 2 |
|PK|your public key|7038B5F***..|
|INITIAL_PORT|Initial port in which the instances will be created consecutively from there|21101|
|EXT_INTERFACE|Network interface which has access to the internet|eth0|
|NETWORK_NAME|Network interface name that is generated through which all instances will work|net-uam|
|CREATE_FILELOG|Generation of file to store logs (1->ON 0->OFF)|1|
|SHOW_LOG_CONSOLE|Log display in the console when executing (1->ON 0->OFF)|1|
|SHOW_DEBUG_CONSOLE|Log display to debug the operation of the script in the console when executing (1->ON 0->OFF)|1|
|FC|Console main color|\033[0m|
|SC|Console secondary color|\033[0m|

##### Start script

```bash
> sudo sh start.sh
```

##### Delete and close everything generated

```bash
> sudo sh clear.sh
```