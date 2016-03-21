HOME_DIR='/var/apartment_api'

cd $HOME_DIR
mkdir -p logs
nohup rackup -p 3000 -o 127.0.0.1 > $HOME_DIR/logs/grape.log 2>&1 &
