#!/bin/bash

# cardano node directory
DIRECTORY=

# create a pid, this way you can ps aux | grep leaderScheduleCheck.sh to see if script is running
if [[ -d "$DIRECTORY/logs" ]]; then 
    echo $$ > $DIRECTORY"/logs/leaderScheduleCheck.pid"; 
else 
    echo "mkdir $DIRECTORY/logs"; 
    echo $$ > $DIRECTORY"/logs/leaderScheduleCheck.pid"; 
fi

# Set your own stake pool ID
STAKE_POOL_ID=""

TESTNET="testnet"
MAINNET="mainnet"

# Edit variable with $TESTNET for Testnet and $MAINNET for Mainnet
network=$TESTNET

# check for vrf.skey presence
if [[ ! -f "$DIRECTORY/vrf.skey" ]]; then echo "vrf.skey not found" >&2 ; exit 127; fi

CCLI=$(which cardano-cli)
if [[ -z $CCLI ]]; then echo "cardano-cli command cannot be found, exiting..." >&2 ; exit 127; fi

JQ=$(which jq)
if [[ -z $JQ ]]; then echo "jq command cannot be found, exiting..." >&2 ; exit 127; fi

read -ra BYRON_GENESIS <<< "$(jq -r '[ .startTime, .protocolConsts.k, .blockVersionData.slotDuration ] |@tsv' < $DIRECTORY$network-byron-genesis.json)"
if [[ -z $BYRON_GENESIS ]]; then echo "BYRON GENESIS config file not loaded correctly" >&2; exit 127; fi

network_magic=""
if [ $network = $TESTNET ]; then
	network_magic="--testnet-magic 1097911063"
elif [ $network = $MAINNET ]; then
	network_magic="--mainnet"
else
	echo "Incorrect network selected, please use $TESTNET or $MAINNET network type" >&2; exit 1
fi


# Check that node is synced
function isSynced(){
	isSynced=false

	sync_progress=$($CCLI query tip $network_magic | jq -r ".syncProgress")
	if [[ $sync_progress == "100.00" ]]; then
		isSynced=true
	fi

	echo $isSynced
}

# Get current epoch
function getCurrentEpoch(){
	echo $($CCLI query tip $network_magic | jq -r ".epoch")
}

# Get epoch start time based on current one
function getEpochStartTime(){
	byron_genesis_start_time=${BYRON_GENESIS[0]}
	byron_k=${BYRON_GENESIS[1]}
	byron_epoch_length=$(( 10 * byron_k ))
	byron_slot_length=${BYRON_GENESIS[2]}

	echo $(( $byron_genesis_start_time + (($(getCurrentEpoch) * $byron_epoch_length * $byron_slot_length) / 1000) ))
}

# Get epoch end time based on the current one
function getEpochEndTime(){
	#calculate currentEpoch Start time + 5 days of epoch duration - 10 minutes(600s) to not overlap with next epoch
	echo $(( $(getEpochStartTime)+(5*86400)-(600) ))
}

# Get current timestamp
function getCurrentTime(){
	echo $(printf '%(%s)T\n' -1)
}

# Convert timestamps to UTC time
function timestampToUTC(){
	timestamp=$1
	echo $(date +"%D %T" -ud @$timestamp)
}

# Find the correct time to run the leaderslot check command
function getLeaderslotCheckTime(){
	epochStartTime=$(getEpochStartTime)
	epochEndTime=$(getEpochEndTime)

	# epoch completion percent to check for --next epoch leaderslots
	percentage=75
	checkTimestamp=$(( $epochStartTime+($percentage*($epochEndTime-$epochStartTime)/100) ))

	echo $checkTimestamp
}

# Function to make the script sleep until check need to be executed
function sleepUntil(){
	sleepSeconds=$1
	if [[ $sleepSeconds -gt 0 ]]; then
		echo "Script is going to sleep for: $sleepSeconds seconds"
		sleep $sleepSeconds
	fi
}

# Check leaderschedule of next epoch
function checkLeadershipSchedule(){
	next_epoch=$(( $(getCurrentEpoch)+1 ))
	currentTime=$(getCurrentTime)

        echo "Check is running at: $(timestampToUTC $currentTime) for epoch: $next_epoch"
	$CCLI query leadership-schedule $network_magic --genesis $DIRECTORY$network-shelley-genesis.json --stake-pool-id $STAKE_POOL_ID --vrf-signing-key-file $DIRECTORY"vrf.skey" --next > $DIRECTORY"logs/leaderSchedule_$next_epoch.txt"
}

if [ isSynced ];then
	echo "Current epoch: $(getCurrentEpoch)"

	epochStartTimestamp=$(getEpochStartTime)
	echo "Epoch start time: $(timestampToUTC $epochStartTimestamp)"

	epochEndTimestamp=$(getEpochEndTime)
	echo "Epoch end time: $(timestampToUTC $epochEndTimestamp)"

	currentTime=$(getCurrentTime)
	echo "Current cron execution time: $(timestampToUTC $currentTime)"

	timestampCheckLeaders=$(getLeaderslotCheckTime)
	echo "Next check time: $(timestampToUTC $timestampCheckLeaders)"

	timeDifference=$(( $timestampCheckLeaders-$currentTime ))
	if [ -f "$DIRECTORY/logs/leaderSchedule_$(( $(getCurrentEpoch)+1 )).txt" ]; then
                echo "Check already done, check logs for results" >&2 ; exit 1
	elif [[ $timeDifference -gt 0 ]] && [[ $timeDifference -gt 86400 ]]; then
                echo "Too early to run the script, wait for next cron scheduled job" >&2 ; exit 1
	elif [[ $timeDifference -gt 0 ]] && [[ $timeDifference -le 86400 ]]; then
		sleepUntil $timeDifference
		echo "Check is starting on $(timestampToUTC $(getCurrentTime))"
	        checkLeadershipSchedule
		echo "Script ended, schedule logged inside file: leaderSchedule_$(( $(getCurrentEpoch)+1 )).txt"
	else
		echo "There were problems on running the script, check that everything is working fine" >&2 ; exit 1
	fi
else
	echo "Node not fully synced." >&2 ; exit 1
fi
