# LeaderSchedule Check via Cronjob
LeaderScheduleCheck for Cardano Stake Pools via Cronjob

The script calculate the correct time to run the cardano-cli query leadership-schedule for the next epoch on a Cardano Stake Pool.<br />
It runs everyday via a configured cron job, if it is too early (too many day in advanced), it quits and the next day job will repeat the process.<br />
If seconds remaining from the check are less than 86400 (24H), it waits the correct time, it runs the check and it sends the output to a log file for future checks.<br />
If the check has been already done, it lets you know that.

## Information:

This process will work with the following method, next epoch blocks can be checked 1.5 days before the start of the next epoch or at the 75% of the current epoch's completition.\
The script will calculate the the correct day and hour to run the command, then wait until it is possible to do that and once the correct time comes, run the leaderschedule check.\
Once finished, it will redirect the output into a log file that can be analyzed.

Keep in mind that running the leadership-schedule command, listed below and used by the script, with the cardano-node at the same time, will use approximately 17GB of RAM at the time of writing this guide (April 2022).

The possible solutions to avoid a node crash are:
- Increase the RAM of the node
- Increase the SWAP partition of the node

## Configuration:

Download the `leaderScheduleCheck.sh` script file in the block producer (script can also be run on a relay node but vrf.skey needs to be exported there)

Set the following variables with your data:

```bash
# cardano node directory, directory where all files needed for running a cardano-node are located
DIRECTORY=

# Set your own stake pool ID
STAKE_POOL_ID=""

# Set variable with $TESTNET for Testnet and $MAINNET for Mainnet
network=
```

Add execution permissions and test that the script is running without errors:

```bash
chmod +x leaderScheduleCheck.sh
./leaderScheduleCheck.sh
```

If everything is working correclty, an output as the follow will be presented:
>Current epoch: 199 \
>Epoch start time: 04/14/22 20:20:16 \
>Epoch end time: 04/19/22 20:10:16 \
>Current cron execution time: 04/18/22 15:37:51 \
>Next check time: 04/18/22 14:12:46 \
>[...]
>Cutted output cause it can vary based on time when the script is runned

Configure `Cronjob` to make the script run automatically:

To configure the job at the start of an epoch, keep in mind the following information:
- Epoch in TESTNET starts at 20:20 UTC
- Epoch in MAINNET starts at 21:45 UTC


Find the time when the cronjob should start (Cronjobs run based on local timezone, not on UTC hours):

Find timezone:

`timedatectl | grep "Time zone"`

Once you found your timezone, you need to understand when run the job (It isn't mandatory to run it at epoch's starting hour). \
Here is an example with a UTC+2 timezone for Mainnet:
> Epoch starting hour UTC: 21:45
> Epoch starting hour for requested timezone: 23:45
> Cronjob will be set to run at 23:45

Add cronjob and edit parameters based on your needs, `PATH`, `NODE_HOME`, `NODE_CONFIG`, `CARDANO_NODE_SOCKET_PATH`, `MM`, `HH`, `path_to_script` and `desired_log_folder`:
```bash 
cat > $NODE_HOME/crontab-fragment.txt << EOF
# linux path, needed because cron doesn't know where to find cardano-cli
PATH=
# folder with cardano-node files
NODE_HOME=
# testnet or mainnet
NODE_CONFIG=
# path to the soket of cardano node, should be under db/ folder under NODE_HOME
CARDANO_NODE_SOCKET_PATH=

MM HH * * * path_to_script/leaderScheduleCheck.sh > desired_log_folder/leaderSchedule_logs.txt 2>&1
EOF
crontab -l | cat - ${NODE_HOME}/crontab-fragment.txt > ${NODE_HOME}/crontab.txt && crontab ${NODE_HOME}/crontab.txt
rm ${NODE_HOME}/crontab-fragment.txt
```


Once the cronjob is set, the script will be run every day and it will check if in the next 24H, it will be the correct time to run the command and see if there are scheduled blocks in the next epoch. \
For every epoch, there will be a file called leaderSchedule_epoch.txt

## Output example:

>Current epoch: 197<br />
>Epoch start time: 04/04/22 20:20:16<br />
>Epoch end time: 04/09/22 20:10:16<br />
>Next check time: 04/08/22 14:12:46<br />
>Current cron execution time: 04/07/22 20:30:01<br />
>Script is going to sleep for: 63720 seconds<br />
>Check is starting on: 04/08/22 14:12:46<br />
>Script ended, schedule logged inside file: leaderSchedule_197.txt<br />

## Contributors
Nik from <a href="https://adapools.org/pool/1c220012e987c342ec4b4c6cea04501d0cf003459804b0e7018d3c73">Alice Stake Pool</a>, helped to improve and test the script


## Todo:
- Add email notification after schedule is calculated / Telegram bot notification
- Analyze the schedule output and convert it into json file to be integrated with Grafana
- Calculate windows between blocks to reboot pool block producer node
- Convert it to a service, enable at start, if noded is rebooted it will still work
- Add epoch summary of final produced blocks
- Reschedule the check if there are nearby blocks
- Change the output redirection management, integrate everything under the script (remove the need to add extra info into crontab)
- Better checking of epoch's start, it could be inaccurate of few minutes, cause epochs don't spart always at 21:45UTC(mainnet)/20:20UTC(testnet) precisely --> find a better way to know when an epoch is started
