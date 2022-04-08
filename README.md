# LeaderSchedule Check via Cronjob
LeaderScheduleCheck for Cardano Stake Pools via Cronjob

The script calculate the correct time to check for next epoch Leaderslot on a Cardano Stake Pool.
It is started at the begining of every epoch and it sleeps until the correct time to run the check, then it output the logs into a file to future checks.

A cronjob needs to be configured, an example can be find [here](https://github.com/Techs2Help/leaderScheduleCheck_cron/blob/main/cronjob.txt)

**Output example:** <br />
Current epoch: 197<br />
Epoch start time: 04/04/22 20:20:16<br />
Epoch end time: 04/09/22 20:10:16<br />
Current cron execution time: 04/08/22 05:43:01<br />
Next check time: 04/08/22 14:12:46<br />
Script is going to sleep for: 30585 seconds<br />
Check is starting on: 04/08/22 14:12:46<br />
Script ended, schedule logged inside file: leaderSchedule_197.txt<br />


## Todo:
- Add email notification after schedule is calculated
- Analyze the schedule output and convert it into json file to be integrated with Grafana
- Calculate windows between blocks to reboot pool block producer node
