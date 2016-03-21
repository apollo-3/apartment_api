ps -ef | grep rackup | grep -v 'grep' | awk {'print $2'} | xargs kill -9
