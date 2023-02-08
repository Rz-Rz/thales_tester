# Thales Test Suite
A fully automated test suite for 42 Philosopher's project.
After working on this project for a number of days, I grew tired of rewriting all my test by hand hundreds of times after each small change in code. The tester I found did not do all the test I needed or were not fully automated so I decided to make my own. I hope it can save you time.

### Acknowledgment
nesvoboda/socrates And newlinuxbot/Philosphers-42Project-Tester whose project inspired my tester.

### Disclaimer
The author of this tester shall not be held responsible for any damage that may result from the usage of this script. This script is provided as is and the user assumes all responsibility and risk associated with its usage. Moreover this tester should not be used during defence.

# Preview
<image src="https://user-images.githubusercontent.com/52322219/217537923-6d43a9cf-284b-4c46-931f-ad065ef850e2.png" width="400px" height="180px">

# Features

### Death Checks

<image src="https://user-images.githubusercontent.com/52322219/217549037-a9cf03eb-efc0-4c4f-926d-0c03a72bf634.png" width="400px" height="210px">

By default this tester performs a number of death cheks. During thoses checks the philosophers must die.

**Death Occurence** The script checks if a died message was printed.
**Proper Simulation Ending** The script checks that the simulation ends properly after the death log (i.e. No message of any kind are logged after the death message).
**Death Timing** The script checks the proper timing of death log.
**Valgrind** The script reruns the program to sanitize it with valgrind. If valgrind detects any error it will be reported in the script as a leak. But it might be an invalid read size, always rerun the failed parameters to see for yourself.
**Helgrind** The script reruns the program to sanitize it with helgrind. If helgrind detects any error it will be reported in the script as a race condition. But it might be a deadlock, always rerun the failed parameters to see for yourself.

### Meal Checks

<img src="https://user-images.githubusercontent.com/52322219/217548851-31e1ef90-da13-4d04-8a45-0d3ca1e5943b.png" width="500px" height="260px" >

By default this tester performs a number of meal checks. During thoses checks the philosophers must not die and eat all their meals thus ending the simulation.

**Meal Occurence** The script checks if each philo has eaten enough meals, and if they have eaten more than they should (No more than nb_of_meals + 2).
**Valgrind** The script reruns the program to sanitize it with valgrind. If valgrind detects any error it will be reported in the script as a leak. But it might be an invalid read size, always rerun the failed parameters to see for yourself.
**Helgrind** The script reruns the program to sanitize it with helgrind. If helgrind detects any error it will be reported in the script as a race condition. But it might be a deadlock, always rerun the failed parameters to see for yourself.

### CPU Usage Checks

<img src="https://user-images.githubusercontent.com/52322219/217548658-7fc31112-0939-49cb-a8ef-15d3dd60d198.png" width="400px" height="180px">

By default this tester performs a number of CPU usage test. The program tested must not use more than 50 % of the CPU during the test. The script keeps track of the CPU usage throughout the test.


### No Death Check

<img src="https://user-images.githubusercontent.com/52322219/217548426-6f6a3336-0c50-4db3-81fd-381958c28119.png" width="600px" height="200px"> 

The tester will launch for 40 seconds the tested program to check how long your program can run.


### Check Program Arguments

<img src="https://user-images.githubusercontent.com/52322219/217548194-6d8d55b8-fd36-49dd-b170-7606abad9ba9.png" width="850px" height="160px">

By default the tester will performs a number of checks with invalid program arguments. It will look for any segfault. If it finds one it will error out. If it doesn't find any, it will check the number of lines in the output. If there is one line, it will check wether invalid|error|wrong are present in the output indicating error handling. If it finds one it will print a success message. If it doesn't find one, it will print out the last two lines and leaves you to decide if the input was correctly handled. Finally if the script doesn't detect any output, it will print a success message.

### Check Insufficient Memory Handling

<img src="https://user-images.githubusercontent.com/52322219/217548015-d9dcbe08-34aa-4197-a697-8ba4fe42fb9c.png" width="650px" height="50px">

The tester will check wether the threads are correctly joined in case of insufficient memory on thread creation. In the case that N-th thread fails because of insufficient memory, and they are not joined, leaks will be detected and reported by the tester. Due to the delicate nature of testing this behavior, here's the test I perform in case you would like to test it for yourself: 
```(ulimit -v 180000; valgrind --leak-check=full --errors-for-leak-kinds=all  "$program_path/$program_name" 85 60 60 60)```

## Bonus Checks
For the bonus, the checks performed are: 
 - Death Checks
 - Meal Checks
 - Program Arguments Checks
 - No Death Checks
And

### Check Number of Forks 

<img src="https://user-images.githubusercontent.com/52322219/217549883-af55c93d-cf3d-42d2-bac7-c2ab2a6a90cd.png" width="500px" height="60px">

The tester will check how many forks were created.

### Contribute

Contributing to this tester is fairly easy. You can use the function already made to add new test. 

**Death Check**: test_philosopher_death "$target" "$1" "1" "800" "200" "200" "1"

Do not change the first and second parameters. 
The third parameters is the nb_of_philo, fourth is time_to_die, fifth is time_to_eat, sixth is time_to_sleep and seventh is the test_number.

**Meal Check**: test_philosopher_meals "$target" "$1" "5" "800" "200" "200" "7" "10"

We only added the nb_of_meals as seventh parameter.

**Check CPU Usage**: check_cpu_usage "$target" "$1" "2" "800" "200" "200" "70" "15" 

Same structure as Meal Check.

**Check No Death**: check_philosophers_nodeath "$target" "$1" "5" "800" "200" "200" "17"

Same structure as death check. For now the function automatically kills at 40 seconds.

**Check Program Argument** : check_program_arguments "$target" "$1" "-5" "600" "200" "200" "5" "18"

Same structure as Meal Check.

As you can see adding checks is pretty straightforward. 

### Feature request
I will add sanity check on the existence of the commands used.
I will add progress bar. 
