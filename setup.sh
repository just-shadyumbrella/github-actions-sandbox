RCLONE_CONF=~/.config/rclone.conf

#sudo apt-get update -y
#sudo apt-get install rclone

curl -Lo $RCLONE_CONF https://github.com/yaudahj/github-actions-sandbox/raw/refs/heads/main/rclone.conf
more $RCLONE_CONF
