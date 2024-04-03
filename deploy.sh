#!/bin/bash

echo "Deleting old app"
sudo rm -rf /var/www/*

echo "Creating app folder"
sudo mkdir -p /var/www/demoapp 

echo "Moving files to app folder"
sudo mv * /var/www/demoapp/

# Navigate to the app directory
cd /var/www/demoapp/

# Rename the environment file if needed (optional)
# sudo mv env .env

sudo apt-get update
echo "Installing Python and pip"
sudo apt-get install -y python3 python3-pip

# Install application dependencies from requirements.txt
echo "Installing application dependencies from requirements.txt"
sudo pip install -r requirements.txt

# Update and install Nginx if not already installed
if ! command -v nginx > /dev/null; then
    echo "Installing Nginx"
    sudo apt-get update
    sudo apt-get install -y nginx
fi

# Configure Nginx to act as a reverse proxy if not already configured
if [ ! -f /etc/nginx/sites-available/myapp ]; then
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo bash -c 'cat > /etc/nginx/sites-available/myapp <<EOF
server {
    listen 80;
    server_name _;

    location / {
        include proxy_params;
        proxy_pass http://unix:/var/www/demoapp/myapp.sock;
    }
}
EOF'

    sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled
    sudo systemctl restart nginx
else
    echo "Nginx reverse proxy configuration already exists."
fi

# Stop any existing Gunicorn process
sudo pkill gunicorn
sudo rm -rf myapp.sock

# Start Gunicorn with the Django application
echo "Starting Gunicorn"
sudo gunicorn --workers 3 --bind unix:/var/www/demoapp/myapp.sock demoproject.wsgi:application --user www-data --group www-data --daemon
echo "Started Gunicorn 🚀"
