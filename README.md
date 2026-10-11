# Sigma Lab

This repo houses a collection of Sigma rules for detecting adversarial actions within cloud environments and endpoints. 

It serves as a personal laboratory for developing, testing, and refining detection logic.


## Setup & Usage

* Running unit tests to test the ruleset requires `rsigma`. Install it using instructions [here](https://github.com/timescale/rsigma).
* `chmod u+x ./tests/rule_tests.sh`
* Run the unit tests (from project root) using `./tests/rule_tests.sh`. 

> [!NOTE]
> If you have downloaded rsigma as a standalone binary, you will need to include it in `PATH` to be able to run this script. If you don't want to modify `PATH` permanently, you can use `PATH=$PATH:. ./tests/rule_tests.sh` (assuming the rsigma binary is also in project root directory).

## Log sources

The logs used in this repo are from [Splunk Attack Data](https://github.com/splunk/attack_data).