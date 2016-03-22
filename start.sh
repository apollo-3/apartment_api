HOME_DIR='/var/apartment_api'

cd $HOME_DIR
mkdir -p logs
./stop.sh > /dev/null 2>&1
nohup rackup -p 3000 -o 0.0.0.0 > $HOME_DIR/logs/grape.log 2>&1 &
