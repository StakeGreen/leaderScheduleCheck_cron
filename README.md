# LeaderSchedule Check via Cronjob
LeaderScheduleCheck for Cardano Stake Pools via Cronjob

The script calculate the correct time to run the cardano-cli query leadership-schedule for the next epoch on a Cardano Stake Pool.<br />
It runs everyday via a configured cron job, if it is too early (too many day in advanced), it quits and the next day job will repeat the process.<br />
If seconds remaining from the check are less than 86400 (24H), it waits the correct time, it runs the check and it sends the output to a log file for future checks.<br />
If the check has been already done, it lets you know that.

A cronjob needs to be configured, an example can be find [here](https://github.com/Techs2Help/leaderScheduleCheck_cron/blob/main/cronjob.txt)

**Output example:** <br />
Current epoch: 197<br />
Epoch start time: 04/04/22 20:20:16<br />
Epoch end time: 04/09/22 20:10:16<br />
Next check time: 04/08/22 14:12:46<br />
Current cron execution time: 04/07/22 20:30:01<br />
Script is going to sleep for: 63720 seconds<br />
Check is starting on: 04/08/22 14:12:46<br />
Script ended, schedule logged inside file: leaderSchedule_197.txt<br />


## Todo:
- Add email notification after schedule is calculated
- Analyze the schedule output and convert it into json file to be integrated with Grafana
- Calculate windows between blocks to reboot pool block producer node
- convert it to a service, enable at start, if noded is rebooted it will still work
- Add epoch summary 10 minutes before epoch ending for produced blocks
