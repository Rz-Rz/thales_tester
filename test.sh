#!/bin/bash
trap 'exit 130' INT # allows exit with C-c
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
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
	local i=0
	echo -e "${yellow}[+] Testing $program_name with ${program_params[@]}${reset}"
	(timeout 20 "$program_path/$program_name" "${program_params[@]}" > "$log_file")

	while [ $i -lt 20 ];do
		pgrep $1 > /dev/null
		if [ "$?" -ne 0 ];then
			break
		fi
		sleep 1
		i=$(( $i + 1 ))
	done
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
  timeout 30 valgrind --leak-check=full --errors-for-leak-kinds=all --error-exitcode=1 "$2/$1" $parameters &> "./valgrind_$1.log"
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
  timeout 30 valgrind --tool=helgrind --error-exitcode=1 "$2/$1" $parameters &> "./helgrind_$1.log"
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
  timeout 30 valgrind --leak-check=full --errors-for-leak-kinds=all --error-exitcode=1 "$2/$1" $parameters &> "./valgrind_$1.log"
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
  timeout 30 valgrind --tool=helgrind --error-exitcode=1 "$2/$1" $parameters &> "./helgrind_$1.log"
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
		local philosopher_eat_count=$(grep -w -c "$i is eating" "$log_file")
		echo -e "${yellow}[+] Philosopher $i ate $philosopher_eat_count times${reset}"
		if [ "$philosopher_eat_count" -lt "$num_meals" ] || [ "$philosopher_eat_count" -gt $((num_meals + 2)) ]; then
			echo "${red}[-] Test #${test_num} Failed: Philosopher $i has not eaten enough times or has eaten too many times${reset}"
			echo "${red}[-] Test #${test_num} Failed: Failed with ${parameters} ${reset}"
			return 1
		fi
	done

  echo "${green}[+] Test #${test_num} Succeeded with params: ${parameters[@]} !${reset}"
}

check_philosophers_nodeath ()
{
	echo -e "\n"
	local program_name="$1"
	local program_path="$2"
	local program_params=("${@:3:4}")
	local test_number="$7"
	local log_file="./log_$program_name"
	echo -e "${yellow}[+] Test #${test_number} Testing $program_name with ${program_params[@]}${reset}"
	(timeout 50 "$program_path/$program_name" "${program_params[@]}" > /dev/null)&
	i=1
    error=0
    while [ $i -lt 40 ];do
        printf "\r[%d...]" $i
        pgrep $1 > /dev/null
        if [ "$?" -ne 0 ];then
            echo "${red}[+] Test #${test_number} Failed with ${program_params[@]}, the philosopher should stay alive for at least 40 seconds${reset}"
            error=1
            break
        fi
		echo "${yellow} ${i}sec - still alive ${reset}"
        sleep 1
        i=$(( $i + 1 ))
    done
    sleep 1
    if [ $error -eq 0 ];then
        pkill $1
        echo "${green}[+] Test #${test_number} Succeeded with ${program_params[@]} ${reset}"
    fi
}

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

    timeout 15 "$program_path/$program_name" "${params[@]}" &>.debug.txt & pid=$!

	pgid=$(ps -o pgid=$pid | grep -o '[1-9]*')
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
	echo -e "\n${green}[+] Test #${test_number} Succeeded: Average CPU usage is $truncated_result for $3 philos${reset} \n"
    kill $pid
	rm .debug.txt
}

check_program_arguments() {
    local program_name="$1"
    local program_path="$2"
    local params=("${@:3:5}")
	local test_number="$8"

    timeout 10 "$program_path/$program_name" "${params[@]}" &> output.txt

    if grep -q "Segmentation fault" output.txt; then
        echo "${red}[+] Test #${test_number} Failed: Program crashed with a segmentation fault error with ${params[@]} ${reset}"
        return 1
    fi

    local output_line_count=$(wc -l < output.txt)
    if [ $output_line_count -gt 1 ]; then
		echo -e "${yellow}[~] Test #${test_number} Program output multiple lines with ${params[@]}, you should decide if this case is handled well. Here are the last 2 lines:\n $(tail -n 2 output.txt) ${reset}\n"
		rm output.txt
        return 1
    elif [ $output_line_count -eq 1 ]; then
		if grep -qEi 'invalid|wrong|error' output.txt; then
			echo -e "${green}[+] Test #${test_number} Program output an error message with ${params[@]}\n"
		else
			echo -e "${yellow}[~] Test #${test_number} Program output with ${params[@]}:\n $(head -n 1 output.txt) ${reset}"
		fi
    else
        echo -e "${green}[+] Test #${test_number} Program ran successfully without errors or output with ${params[@]}\n"
    fi
	rm output.txt
}

check_number_of_forks ()
{
    local program_name="$1"
    local program_path="$2"
    local params=("${@:3:4}")
	local test_number="$7"
	(timeout 10 "$program_path/$program_name" "${params[@]}" &> /dev/null)&

	sleep 1
	forks=$(pgrep $1 | wc -l)
    if [ "$forks" -eq ${params[3]} ];then
        echo -e "${green}[+] Test #${test_number} Succeeded: Program created 10 forks with ${params[@]} ${reset}\n"
    else
        echo -e "${red}[+] Test #{test_number} Failed: Program created $forks forks with ${params[@]} ${reset}\n"
    fi
    pkill $1

}

check_secure_thread_creation () {
    local program_name="$1"
    local program_path="$2"
	local test_number="$3"

	result=$( (timeout 10 ulimit -v 175000; valgrind --leak-check=full --errors-for-leak-kinds=all  "$program_path/$program_name" 10 60 60 60) 2>&1 )

	if echo "$result" | grep -q "ERROR SUMMARY: 0 errors"; then
		echo -e "${green}[+] Test #${test_number} Threads are protected during initialization agaisn't insufficient memory, no errors found${reset} \n"
	else
		echo -e "${red}[+] Test #${test_number} Threads are not protected during initialization agaisn't insufficient memory. ${reset} \n"
	fi
}


if [ "$2" -eq 1 -o "$2" -eq 0 ];then

    echo -e "\n\t\t${green}[============[Testing philo]==============]${reset}"

    target="philo"
    make -C "$1/" > /dev/null

    if [ "$?" -ne 0 ];then
        echo -e "\n\t${red}[+] There's a problem while compiling $target, please recheck your inputs${reset}"
        exit
    fi

	echo -e "\n\t\t${green}[============[ Death Checks ]==============]${reset}\n"

	test_philosopher_death "$target" "$1" "1" "800" "200" "200" "1"
	test_philosopher_death "$target" "$1" "4" "310" "200" "100" "2"
	test_philosopher_death "$target" "$1" "4" "200" "205" "200" "3"
	test_philosopher_death "$target" "$1" "5" "599" "200" "200" "4"
	test_philosopher_death "$target" "$1" "5" "300" "60" "600" "5"
	test_philosopher_death "$target" "$1" "5" "60" "60" "60" "6"
	test_philosopher_death "$target" "$1" "200" "60" "60" "60" "7"
	test_philosopher_death "$target" "$1" "200" "300" "60" "600" "8"
	test_philosopher_death "$target" "$1" "199" "800" "300" "100" "9"

	echo -e "\n\t\t${green}[============[ Meal Checks ]==============]${reset}\n"

	test_philosopher_meals "$target" "$1" "5" "800" "200" "200" "7" "10"
	test_philosopher_meals "$target" "$1" "3" "800" "200" "200" "7" "11"
	test_philosopher_meals "$target" "$1" "2" "800" "200" "200" "7" "12"
	test_philosopher_meals "$target" "$1" "4" "410" "200" "200" "10" "13"
	test_philosopher_meals "$target" "$1" "2" "410" "200" "200" "10" "14"
	test_philosopher_meals "$target" "$1" "200" "410" "200" "200" "10" "14"
	test_philosopher_meals "$target" "$1" "199" "610" "200" "200" "10" "15"
	test_philosopher_meals "$target" "$1" "199" "610" "200" "80" "10" "16"
	test_philosopher_meals "$target" "$1" "200" "410" "200" "80" "10" "17"

	echo -e "\n\t\t${green}[============[ CPU Checks ]==============]${reset}\n"

	check_cpu_usage "$target" "$1" "2" "800" "200" "200" "70" "18"
	check_cpu_usage "$target" "$1" "10" "800" "200" "200" "70" "19"
	check_cpu_usage "$target" "$1" "50" "800" "200" "200" "70" "20"

	echo -e "\n\t\t${green}[============[ Running Philo for 40 Seconds ]==============]${reset}\n"

	check_philosophers_nodeath "$target" "$1" "5" "800" "200" "200" "21"
	check_philosophers_nodeath "$target" "$1" "5" "800" "200" "150" "22"
	check_philosophers_nodeath "$target" "$1" "3" "610" "200" "80" "23"
	check_philosophers_nodeath "$target" "$1" "3" "610" "200" "200" "24"
	check_philosophers_nodeath "$target" "$1" "199" "610" "200" "80" "25"
	check_philosophers_nodeath "$target" "$1" "200" "410" "200" "80" "26"
	check_philosophers_nodeath "$target" "$1" "200" "410" "200" "200" "27"

	echo -e "\n\t\t${green}[============[ Testing Invalid Arguments ]==============]${reset}\n"

	check_program_arguments "$target" "$1" "-5" "600" "200" "200" "5" "28"
	check_program_arguments "$target" "$1" "5" "-5" "200" "200" "5" "29"
	check_program_arguments "$target" "$1" "5" "600" "-5" "200" "5" "30"
	check_program_arguments "$target" "$1" "5" "600" "200" "-5" "5" "31"
	check_program_arguments "$target" "$1" "5" "600" "200" "200" "-5" "32"
	check_program_arguments "$target" "$1" "5" "2147483649" "200" "200" "5" "33"
	check_program_arguments "$target" "$1" "5" "200" "2147483649" "200" "5" "34"
	check_program_arguments "$target" "$1" "2147483649" "200" "200" "200" "5" "35"
	check_program_arguments "$target" "$1" "5" "200" "200" "200" "2147483649" "36"
	check_program_arguments "$target" "$1" "5" "200" "200" "2147483649" "5" "37"

	echo -e "\n\t\t${green}[============[ Error on Threads Creation ]==============]\n${reset}"
	check_secure_thread_creation "$target" "$1" "38"

    rm -rf "./log_$target"
fi

if [ "$2" -eq 2 -o "$2" -eq 0 ];then

    echo -e "\n[============[Testing philo_bonus]==============]\n"

    target="philo_bonus"
    make -C "$1/" > /dev/null

    if [ "$?" -ne 0 ];then
        echo "\n[+] There's a problem while compiling $target, please recheck your inputs"
        exit
    fi

	test_philosopher_death "$target" "$1" "1" "800" "200" "200" "1"
	test_philosopher_death "$target" "$1" "4" "310" "200" "100" "2"
	test_philosopher_death "$target" "$1" "4" "200" "205" "200" "3"
	test_philosopher_death "$target" "$1" "5" "599" "200" "200" "4"
	test_philosopher_death "$target" "$1" "5" "300" "60" "600" "5"
	test_philosopher_death "$target" "$1" "5" "60" "60" "60" "6"
	test_philosopher_death "$target" "$1" "200" "60" "60" "60" "7"
	test_philosopher_death "$target" "$1" "200" "300" "60" "600" "8"
	test_philosopher_death "$target" "$1" "199" "800" "300" "100" "9"

	test_philosopher_meals "$target" "$1" "5" "800" "200" "200" "7" "10"
	test_philosopher_meals "$target" "$1" "3" "800" "200" "200" "7" "11"
	test_philosopher_meals "$target" "$1" "2" "800" "200" "200" "7" "12"
	test_philosopher_meals "$target" "$1" "4" "410" "200" "200" "10" "13"
	test_philosopher_meals "$target" "$1" "2" "410" "200" "200" "10" "14"
	test_philosopher_meals "$target" "$1" "200" "410" "200" "200" "10" "15"
	test_philosopher_meals "$target" "$1" "199" "610" "200" "200" "10" "16"
	test_philosopher_meals "$target" "$1" "200" "410" "200" "80" "10" "17"
	test_philosopher_meals "$target" "$1" "199" "610" "200" "80" "10" "18"

	check_philosophers_nodeath "$target" "$1" "5" "800" "200" "200" "19"
	check_philosophers_nodeath "$target" "$1" "5" "800" "200" "150" "20"
	check_philosophers_nodeath "$target" "$1" "3" "610" "200" "80" "21"
	check_philosophers_nodeath "$target" "$1" "199" "610" "200" "80" "22"
	check_philosophers_nodeath "$target" "$1" "199" "610" "200" "200" "23"
	check_philosophers_nodeath "$target" "$1" "200" "410" "200" "80" "24"
	check_philosophers_nodeath "$target" "$1" "200" "410" "200" "200" "25"

	check_number_of_forks "$target" "$1" "10" "800" "200" "200" "26"
	check_number_of_forks "$target" "$1" "100" "800" "200" "200" "27"
	check_number_of_forks "$target" "$1" "200" "800" "200" "200" "28"

    rm -rf "./log_$target"
fi
