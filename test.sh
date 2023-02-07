#!/bin/bash
trap 'exit 130' INT # allows exit with C-c
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

if [ "$#" -ne 2 ]; then
    echo " ${yellow}Usage: start.sh <Project Folder> <Test Type>"
    echo -e "\tType 0: test philo, and philo_bonus"
    echo -e "\tType 1: test philo only"
    echo -e "\tType 2: test philo_bonus only${reset}"

    exit
fi

if [ "$2" -gt 2 -o "$2" -lt 0 ]; then
    echo "${Red}[Error]: Wrong Arguments${reset}"
    exit
fi

echo -e "${yellow}[+] Given Folder: $1"
echo -e "[+] Test Type: $2"
echo -e "[+] In Case of a failed test, please check ./errors_log file for more information${reset}\n"

error_log ()
{
    echo "[$1-$2]: $3" >> ./errors_log
}

test_philosopher_death () {
	echo -e "\n"
	local program_name="$1"
	local program_path="$2"
	local params=("${@:3:4}")
	local test_number="$7"
	local log_file="./log_$program_name"
	echo -e "${yellow}[+] Testing $program_name with ${params[@]}${reset}"
	(timeout 10 "$program_path/$program_name" "${params[@]}" > "$log_file")

	check_cpu_usage "$pid"
	check_death_occurred  "$test_number" "$log_file"
	check_simulation_ends "$test_number" "$log_file"
	death_timing "$log_file" "${params[1]}" "$test_number"
	test_valgrind $1 $2 $3 $4 $5 $6 $7 $test_number
	test_helgrind $1 $2 $3 $4 $5 $6 $7 $test_number

  rm -rf "$log_file"
}

death_timing() {
  file=$1
  time_to_die=$2
  test_num=$3
  
  while read line; do
    timestamp=$(echo $line | awk '{print $1}')
    if [[ $line == *"died"* ]]; then
      error=$(($timestamp - $time_to_die))
      if (( $timestamp < $time_to_die || $timestamp > $(($time_to_die + 10)) )); then
        echo "${red}[-] Test #${test_num} Error: Timestamp is incorrect with an error of $error ms ($timestamp)${reset}"
      else
        echo "${green}[+] Test #${test_num} Timestamp is correct with an error of $error ms${reset}"
      fi
      break
    fi
  done < $file
}

test_philosopher_meals () {
	echo -e "\n"
	local program_name="$1"
	local program_path="$2"
	local program_params=("${@:3:5}")
	local test_number="$8"
	local log_file="./log_$program_name"
	echo -e "${yellow}[+] Testing $program_name with ${program_params[@]}${reset}"
	(timeout 10 "$program_path/$program_name" "${program_params[@]}" > "$log_file")

	check_philosophers_eat "$log_file" "$3" "$7" "$test_number" "${program_params[@]}"
	rm -rf "$log_file"
	test_valgrind_meals $1 $2 $3 $4 $5 $6 $7 $8 $test_number
	test_helgrind_meals $1 $2 $3 $4 $5 $6 $7 $8 $test_number
}


check_death_occurred () {
  local test_num="$1"
  local log_file="$2"
  local death_count=$(grep -c died "$log_file")

  if [ "$death_count" -eq 0 ]; then
    echo "${red}[-] Test #${test_num} Failed: No death${reset}"
    return 1
  elif [ "$death_count" -gt 1 ]; then
    echo "${red}[-] Test #${test_num} Failed: More than one death${reset}"
    return 1
  fi

  echo "${green}[+] Test #${test_num} Succeeded ! Only one death occured.${reset}"
}

check_simulation_ends () {
  local test_num="$1"
  local log_file="$2"
  local after_death=$(sed -n '/died/{n;p;}' "$log_file")

  if [ -n "$after_death" ]; then
    echo "${red}[-] Test #${test_num} Failed: Simulation does not end after a death${reset}"
    return 1
  fi

  echo "${green}[+] Test #${test_num} Succeeded ! Simulation ends after death${reset}"
}

test_valgrind () {
  local parameters="$3 $4 $5 $6 $7"
  local test_num="$8"
  timeout 8 valgrind --leak-check=full --errors-for-leak-kinds=all --error-exitcode=1 "$2/$1" $parameters &> "./valgrind_$1.log"
  if [ $? -eq 0 ]; then
    echo "${green}[+] Test #${test_num} Valgrind Test Succeeded !${reset}"
  else
    echo "${red}[-] Test #${test_num} Valgrind Test Failed: Memory leaks detected${reset}"
  fi
  rm -rf "./valgrind_$1.log"
}

test_helgrind () {
  local parameters="$3 $4 $5 $6 $7"
  local test_num="$8"
  timeout 10 valgrind --tool=helgrind --error-exitcode=1 "$2/$1" $parameters &> "./helgrind_$1.log"
  if [ $? -eq 0 ]; then
    echo "${green}[+] Test #${test_num} Helgrind Test Succeeded !${reset}"
  else
    echo "${red}[-] Test #${test_num} Helgrind Test Failed: Race conditions detected${reset}"
  fi
  rm -rf "./helgrind_$1.log"
}

test_valgrind_meals () {
  local parameters="$3 $4 $5 $6 $7"
  local test_num="$8"
  timeout 20 valgrind --leak-check=full --errors-for-leak-kinds=all --error-exitcode=1 "$2/$1" $parameters &> "./valgrind_$1.log"
  if [ $? -eq 0 ]; then
    echo "${green}[+] Test #${test_num} Valgrind Test Succeeded !${reset}"
  else
    echo "${red}[-] Test #${test_num} Valgrind Test Failed: Memory leaks detected${reset}"
  fi
  rm -rf "./valgrind_$1.log"
}

test_helgrind_meals () {
  local parameters="$3 $4 $5 $6 $7"
  local test_num="$8"
  timeout 20 valgrind --tool=helgrind --error-exitcode=1 "$2/$1" $parameters &> "./helgrind_$1.log"
  if [ $? -eq 0 ]; then
    echo "${green}[+] Test #${test_num} Helgrind Test Succeeded !${reset}"
  else
    echo "${red}[-] Test #${test_num} Helgrind Test Failed: Race conditions detected${reset}"
  fi
  rm -rf "./helgrind_$1.log"
}


check_philosophers_eat () {
	local log_file="$1"
	local num_philosophers="$2"
	local num_meals="$3"
	local test_num="$4"
	local parameters="${@:5}"


	for (( i=1; i<=num_philosophers; i++ ))
	do
		local philosopher_eat_count=$(grep -c "$i is eating" "$log_file")
		echo -e "${yellow}[+] Philosopher $i ate $philosopher_eat_count times${reset}"
		if [ "$philosopher_eat_count" -lt "$num_meals" ] || [ "$philosopher_eat_count" -gt $((num_meals + 2)) ]; then
			echo "${red}[-] Test #${test_num} Failed: Philosopher $i has not eaten enough times or has eaten too many times${reset}"
			echo "${red}[-] Test #${test_num} Failed: Failed with ${parameters} ${reset}"
			return 1
		fi
	done

  echo "${green}[+] Test #${test_num} Succeeded with params: ${parameters[@]} !${reset}"
}

# check_cpu_usage() {
# 	local program_name="$1"
# 	local program_path="$2"
# 	local params=("${@:3:4}")
# 	local test_number="$7"
# 	local pid=0

# 	timeout 90 "$program_path/$program_name" "${params[@]}" &>/dev/null & pid=$!
	
# 	echo "pid = ${pid}"
# 	wait $pid

# 	sleep 5
# 	cpu_usage=$(ps -p $pid -o %cpu | awk 'NR==2')
# 	echo "cpu_usage = $cpu_usage"
# 	# if (( $(echo "$cpu_usage > 30" | bc -l) )); then
# 	# 	echo "Error: CPU usage is too high ($cpu_usage%)"
# 	# 	exit 1
# 	# else
# 	# 	echo "CPU usage is within acceptable limits ($cpu_usage%)"
# 	# fi
# }

check_cpu_usage() {
    local program_name="$1"
    local program_path="$2"
    local params=("${@:3:5}")
    local test_number="$7"
    local pid=0
    local start_time=$(date +%s)
    local end_time=$((start_time + 10))
    local current_time=0
	local cpu_usage_sum=0
	local cpu_usage_count=0
	local truncated_result=0
	local pgid=0

    "$program_path/$program_name" "${params[@]}" &>.debug.txt & pid=$!
    
	pgid=$(ps -o pgid= $pid | grep -o '[0-9]*')
	sleep 1
    while [ $current_time -lt $end_time ]; do
        current_time=$(date +%s)
        cpu_usage=$(ps -C "$program_name" -o %cpu | awk 'NR>1 {sum+=$1} END {printf "%.2f\n", sum}')
        echo "${yellow} CPU usage: $cpu_usage% ${reset}"
		if [ $(echo "$cpu_usage > 50" | bc -l) -eq 1 ]; then
			echo -e "${red}[-] Test #${test_number} Failed: CPU usage is too high ($cpu_usage%) with $3 philos${reset} \n"
			kill &pid

			return 1
		fi
		cpu_usage_sum="$(echo "$cpu_usage_sum + $cpu_usage" | bc -l)"
		cpu_usage_count=$((cpu_usage_count + 1))
        sleep 1
    done

	average_cpu_usage="$(echo "$cpu_usage_sum / $cpu_usage_count" | bc -l)"
	truncated_result=$(printf "%.2f%%\n" $average_cpu_usage) 
	echo -e "${green}[+] Test #${test_number} Succeeded: Average CPU usage is $truncated_result for $3 philos${reset} \n"
    kill $pid
}

if [ "$2" -eq 1 -o "$2" -eq 0 ];then

    echo -e "[============[Testing philo]==============]\n"

    target="philo"
    make -C "$1/" > /dev/null

    if [ "$?" -ne 0 ];then
        echo "\n${red}[+] There's a problem while compiling $target, please recheck your inputs${reset}"
        exit
    fi

	# test_philosopher_death "$target" "$1" "1" "800" "200" "200" "1"
	# test_philosopher_death "$target" "$1" "4" "310" "200" "100" "2"
	# test_philosopher_death "$target" "$1" "4" "200" "205" "200" "3"
	# test_philosopher_death "$target" "$1" "5" "599" "200" "200" "4"
	# test_philosopher_death "$target" "$1" "5" "300" "60" "600" "5"
	# test_philosopher_death "$target" "$1" "5" "60" "60" "60" "6"
	# test_philosopher_death "$target" "$1" "200" "60" "60" "60" "7"
	# test_philosopher_death "$target" "$1" "200" "300" "60" "600" "8"
	# test_philosopher_death "$target" "$1" "199" "800" "300" "100" "9"

	# test_philosopher_meals "$target" "$1" "5" "800" "200" "200" "7" "10"
	# test_philosopher_meals "$target" "$1" "3" "800" "200" "200" "7" "11"
	# test_philosopher_meals "$target" "$1" "2" "800" "200" "200" "7" "12"
	# test_philosopher_meals "$target" "$1" "4" "410" "200" "200" "10" "13"
	# test_philosopher_meals "$target" "$1" "2" "410" "200" "200" "10" "14"

	

	# check_cpu_usage "$target" "$1" "2" "800" "200" "200" "70" "15"
	check_cpu_usage "$target" "$1" "10" "800" "200" "200" "70" "16"
    rm -rf "./log_$target"
fi

