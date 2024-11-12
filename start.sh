#!/bin/sh
if ! [ -f /tmp/wait ]; then
	echo "185" > /tmp/wait
else
	wait=$( expr $(cat /tmp/wait) + 10 )
	echo $wait > /tmp/wait
fi

LoadAdmin() {
  if [ -f /opt/tak/CoreConfig.xml ]; then
	echo "FOUND THE CONFIG ... WTF? "
  else
	echo " NO CONFIG" 
	exit
  fi
  echo "Loading Admin cert"
  cd /opt/tak && java -jar utils/UserManager.jar certmod -A certs/files/admin.pem 
  ERROR="$?"
  if [ $ERROR -ne 0 ]; then
    echo -e "Looks like cert loading failed\n$ERROR"
    echo "Exiting to force container restart"
    exit
  else 
    echo " I guess it worked ... "
    # We'll look for this on startup and skip the AdminLoad if it exists.
    touch /tmp/admin.loaded
    echo " Exiting to force container resart on new cert "
    exit
  fi

}

# Starting TAK server initialization
echo "Starting TAK server initialization..."

# Check if certs already exist before generating
if [ ! -f /opt/tak/certs/files/ca.pem ]; then
  echo "Certificates not found. Generating new certificates..."
  cd /opt/tak/certs && export CA_NAME='TAKServer' && ./generateClusterCerts.sh
  echo "Certificates generated successfully."
else
  echo "Certificates already exist. Skipping generation."
fi

# Run TAK server setup script
echo "Running TAK server setup script..."
/opt/tak/configureInDocker.sh init &>> /opt/tak/logs/takserver.log &
echo "Waiting for $(cat /tmp/wait) seconds"
sleep $(cat /tmp/wait)

if ! [ -f /tmp/admin.loaded ]; then
	LoadAdmin 
fi

# Keep the container alive by tailing the log files
echo "Starting log tailing..."
tail -F /opt/tak/logs/*.log

