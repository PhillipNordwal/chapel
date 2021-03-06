#!/usr/bin/env bash
#
# Run performance tests on chap04 with default configuration.

CWD=$(cd $(dirname $0) ; pwd)
source $CWD/common-perf.bash
$CWD/nightly -cron -performance-description 'default --genGraphOpts "-m default -m qthreads"' -releasePerformance -numtrials 5 -startdate 07/28/12
