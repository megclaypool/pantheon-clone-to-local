#!/bin/bash

# If you prefer, you can set these variables manually before running the script. 
# Otherwise, you'll be setting them interactively when you run the script :)

SITE_MACHINE_NAME=''
# SITE_TYPE can be WP, D7, or D8 -- leave blank to autodetect
SITE_TYPE=''
SITE_ENV=''
SQL_USERNAME=''
SQL_PASSWORD=''
# COPY_FILES can be yes or no
COPY_FILES=''




# Don't mess with the stuff below here! #
#########################################

# Check that mysql is installed
command -v mysql >/dev/null 2>&1 || { echo >&2 "This script uses mysql, which you don't seem to have installed yet... Please install mysql and try running this script again :)"; exit 1; }

# Check that terminus is installed
command -v terminus >/dev/null 2>&1 || { echo >&2 "This script uses terminus, which you don't seem to have installed yet... Please install terminus and try running this script again :)"; exit 1; }

# Check that robo is installed
command -v robo >/dev/null 2>&1 || { echo >&2 "This script uses robo, which you don't seem to have installed yet... Please install robo and try running this script again :)"; exit 1; }


# Set a whole bunch of variables #
##################################

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# if $SITE_MACHINE_NAME isn't set above, prompt the user
if [ -z "$SITE_MACHINE_NAME" ]
then
  echo "Enter the pantheon machine name for this site"
  read SITE_MACHINE_NAME
fi

# use terminus to get the site's id number (needed for the clone address)
SITE_ID=$(terminus site:info --field id -- $SITE_MACHINE_NAME)
# if $SITE_ID isn't set after running the above, there's probably an error in the SITE_MACHINE_NAME
while [ -z "$SITE_ID" ]
  do
    echo -e "It looks like you may have entered the machine name of your site incorrectly; Terminus is returning an error instead of a site id... \n\nYou can find the machine name of your site by visiting the site's Pantheon dashboard and clicking the tab for the dev environment. Then click the \"Visit Development Site\" button. The site's machine name is the bit between \"dev-\" and \".pantheonsite.io\" in the url. \n\nPlease enter the machine name of your site"
    read SITE_MACHINE_NAME
    SITE_ID=$(terminus site:info --field id -- $SITE_MACHINE_NAME)
  done


# if $SITE_TYPE isn't set above try to figure it out based on the upstream. 
SITE_UPSTREAM=$(terminus site:info --field upstream -- $SITE_MACHINE_NAME)
if [ -z "$SITE_TYPE" ]
then
  if [[ $SITE_UPSTREAM == *"WordPress"* ]] || [[ $SITE_UPSTREAM == *"wordpress-upstream"* ]]
  then
    echo "This is a WordPress site"
    SITE_TYPE="WP"
  fi

  if [[ $SITE_UPSTREAM == *"drops-7"* ]]
  then
    echo "This is a Drupal 7 site"
    SITE_TYPE="D7"
  fi

  if [[ $SITE_UPSTREAM == *"drops-8"* ]]
  then
    echo "This is a Drupal 8 site"
    SITE_TYPE="D8"
  fi
fi

# if I couldn't figure out the $SITE_TYPE from the upstream, prompt the user
if [ -z "$SITE_TYPE" ]
then
  echo -e "\nIs this a WP site, a D7 site, or a D8 site?"
  read SITE_TYPE
  SITE_TYPE=$( echo "$SITE_TYPE" | tr '[:lower:]' '[:upper:]')

  while [ "${SITE_TYPE}" != "WP" ] && [ "${SITE_TYPE}" != "D7" ] && [ "${SITE_TYPE}" != "D8" ]
    do
      echo "Please use 'WP', 'D7', or 'D8' to describe this site"
      read SITE_TYPE
      SITE_TYPE=$( echo "$SITE_TYPE" | tr '[:lower:]' '[:upper:]')
    done
fi

# if $SITE_ENV isn't set above, prompt the user
if [ -z "$SITE_ENV" ]
then
  echo -e "\nFrom which environment would you like to clone the database and (possibly) files?"
  read SITE_ENV
fi

# if $COPY_FILES isn't set above, prompt the user
if [ -z "$COPY_FILES" ]
then
  echo -e "\nWould you like to download all the site's files, in addition to the code and database? (Yes / No)"
  read COPY_FILES
    COPY_FILES=$( echo "$COPY_FILES" | tr '[:upper:]' '[:lower:]' )
    if [ "${COPY_FILES}" == "y" ]
      then
        COPY_FILES='yes'
    fi
    if [ "${COPY_FILES}" == "n" ]
      then
        COPY_FILES='no'
    fi
    while [ "${COPY_FILES}" != "yes" ] && [ "${COPY_FILES}" != "no" ]
    do
      echo -e "\nerr... That was a yes or no question... Let's try again: Would you like to download all the site's files, in addition to the code and database? (Yes / No)"
      read COPY_FILES
      COPY_FILES=$( echo "$COPY_FILES" | tr '[:upper:]' '[:lower:]' )
    done
    if [ "${COPY_FILES}" == "no" ]
      then
      echo -e "\nOk, I won't download the files right now. You can download them later using the command \"robo pullfiles\"."
    fi
fi

# if $SQL_USERNAME isn't set above, prompt the user
if [ -z "$SQL_USERNAME" ]
then
  echo -e "\nEnter your mysql username"
  read SQL_USERNAME
fi

# if $SQL_PASSWORD isn't set above, prompt the user
if [ -z "$SQL_PASSWORD" ]
then
  echo -e "\nEnter your mysql password (hit enter if you don't have a password set)"
  read SQL_PASSWORD
fi

# set the sql database name based on the site machine name
SQL_DATABASE=${SITE_MACHINE_NAME//-/_}

DB_EXISTS=$(mysql -u $SQL_USERNAME -e "use ${SQL_DATABASE}" 2> /dev/null; echo "$?")




# Now to start actually doing stuff! #
######################################

# if the sql database already exists, drop it and create a new one
if [ -z "$SQL_PASSWORD" ]
  then
    if [ $DB_EXISTS == 0 ]
      then
          mysql -u$SQL_USERNAME -e "drop database $SQL_DATABASE"
      fi
    mysql -u $SQL_USERNAME -e "create database $SQL_DATABASE"
  else
    if [ $DB_EXISTS == 0 ]
      then
        mysql -u$SQL_USERNAME -p$SQL_PASSWORD -e "drop database $SQL_DATABASE"
    fi
    mysql -u$SQL_USERNAME -p$SQL_PASSWORD -e "create database $SQL_DATABASE"
fi

# clone the site code from pantheon
git clone ssh://codeserver.dev.${SITE_ID}@codeserver.dev.${SITE_ID}.drush.in:2222/~/repository.git ${SITE_MACHINE_NAME}

# change to the site directory
cd ${SITE_MACHINE_NAME}

# if the Robo files already exist, delete them (we want to have the latest version)
if [ -f 'RoboFile.php' ]
  then
    rm RoboFile.php
fi

if [ -f 'RoboLocal.php' ]
  then
    rm RoboLocal.php
fi

if [ -f 'RoboLocal.example.php' ]
  then
    rm RoboLocal.example.php
fi

# Snag an up-to-date copy of the RoboFile 
cp ${SCRIPT_DIR}/assets/RoboFile.php ./RoboFile.php

# Add RoboLocal.php to .gitignore if it's not already there
if [ -f .gitignore ]
then
  if ! grep -q "RoboLocal.php" ".gitignore"
  then
    echo -e "\n\n# Local Robo Settings #\n#######################\nRoboLocal.php" >> .gitignore
  fi
else  
  touch .gitignore
  echo -e "\n\n# Local Robo Settings #\n#######################\nRoboLocal.php" >> .gitignore
fi



# Depending on what kind of site this is, copy over the right version of RoboLocal
# Also copy over the local config or settings file and then find and replace variables
if [ "${SITE_TYPE}" == "WP" ]
  then
    # check for /web directory
    if [ -d ./web ]
      then
        DIRECTORY_PATH='./web'
      else
        DIRECTORY_PATH='.'
    fi
    cp ${SCRIPT_DIR}/assets/wordpress.RoboLocal.php ./RoboLocal.php
    cp ${SCRIPT_DIR}/assets/wordpress.RoboLocal.php ./RoboLocal.example.php
    cp ${SCRIPT_DIR}/assets/wordpress.wp-config-local.php ${DIRECTORY_PATH}/wp-config-local.php

    

    sed -i '' -e "s/LOCAL_DATABASE_NAME_PLACEHOLDER/$SQL_DATABASE/g" ${DIRECTORY_PATH}/wp-config-local.php
    sed -i '' -e "s/MYSQL_USERNAME_PLACEHOLDER/$SQL_USERNAME/g" ${DIRECTORY_PATH}/wp-config-local.php
    sed -i '' -e "s/MYSQL_PASSWORD_PLACEHOLDER/$SQL_PASSWORD/g" ${DIRECTORY_PATH}/wp-config-local.php
    
    if [ "${DIRECTORY_PATH}" == "./web" ]
      then
        sed -i '' -e "s/\'wp-content\/uploads\'/\'web\/wp-content\/uploads\'/g" ./RoboLocal.php
        sed -i '' -e "s/\'wp-content\/uploads\'/\'web\/wp-content\/uploads\'/g" ./RoboLocal.example.php
    fi

    # make sure wp-config-local is listed in the .gitignore
    if ! grep -q "wp-config-local.php" ".gitignore"
    then
      echo -e "\n\n# Local Settings #\n##################\nwp-config-local.php" >> .gitignore
    fi
fi

if [ "${SITE_TYPE}" == "D7" ]
  then
    # check for /web directory
    if [ -d ./web ]
      then
        DIRECTORY_PATH='./web'
      else
        DIRECTORY_PATH='.'
    fi
    cp ${SCRIPT_DIR}/assets/drupal.RoboLocal.php ./RoboLocal.php
    cp ${SCRIPT_DIR}/assets/drupal.RoboLocal.php ./RoboLocal.example.php
    cp ${SCRIPT_DIR}/assets/drupal7.settings.local.php ${DIRECTORY_PATH}/sites/default/settings.local.php

    sed -i '' -e "s/LOCAL_DATABASE_NAME_PLACEHOLDER/$SQL_DATABASE/g" ${DIRECTORY_PATH}/sites/default/settings.local.php
    sed -i '' -e "s/MYSQL_USERNAME_PLACEHOLDER/$SQL_USERNAME/g" ${DIRECTORY_PATH}/sites/default/settings.local.php
    sed -i '' -e "s/MYSQL_PASSWORD_PLACEHOLDER/$SQL_PASSWORD/g" ${DIRECTORY_PATH}/sites/default/settings.local.php
    
    if [ "${DIRECTORY_PATH}" == "./web" ]
      then
        sed -i '' -e "s/\'sites\/default\/files\'/\'web\/sites\/default\/files\'/g" ./RoboLocal.php
        sed -i '' -e "s/\'sites\/default\/files\'/\'web\/sites\/default\/files\'/g" ./RoboLocal.example.php
    fi

    # make sure settings.local is listed in the .gitignore
    if ! grep -q "settings.local.php" ".gitignore"
    then
      echo -e "\n\n# Local Settings #\n##################\nsettings.local.php" >> .gitignore
    fi
fi

if [ "${SITE_TYPE}" == "D8" ]
  then
    if [ -d ./web ]
      then
        DIRECTORY_PATH='./web'
      else
        DIRECTORY_PATH='.'
    fi
    cp ${SCRIPT_DIR}/assets/drupal.RoboLocal.php ./RoboLocal.php
    cp ${SCRIPT_DIR}/assets/drupal.RoboLocal.php ./RoboLocal.example.php
    cp ${SCRIPT_DIR}/assets/drupal8.settings.local.php ${DIRECTORY_PATH}/sites/default/settings.local.php
    cp ${SCRIPT_DIR}/assets/drupal8.services.local.yml ${DIRECTORY_PATH}/sites/default/services.local.yml

    sed -i '' -e "s/LOCAL_DATABASE_NAME_PLACEHOLDER/$SQL_DATABASE/g" ${DIRECTORY_PATH}/sites/default/settings.local.php
    sed -i '' -e "s/MYSQL_USERNAME_PLACEHOLDER/$SQL_USERNAME/g" ${DIRECTORY_PATH}/sites/default/settings.local.php
    sed -i '' -e "s/MYSQL_PASSWORD_PLACEHOLDER/$SQL_PASSWORD/g" ${DIRECTORY_PATH}/sites/default/settings.local.php
    
    if [ "${DIRECTORY_PATH}" == "./web" ]
      then
        sed -i '' -e "s/\'sites\/default\/files\'/\'web\/sites\/default\/files\'/g" ./RoboLocal.php
        sed -i '' -e "s/\'sites\/default\/files\'/\'web\/sites\/default\/files\'/g" ./RoboLocal.example.php
    fi

    # make sure settings.local is listed in the .gitignore
    if ! grep -q "settings.local.php" ".gitignore"
    then
      echo -e "\n\n# Local Settings #\n##################\nsettings.local.php" >> .gitignore
    fi

    # make sure services.local is listed in the .gitignore
    if ! grep -q "services.local.yml" ".gitignore"
    then
      echo -e "\n\n# Local Debug Settings #\n########################\nservices.local.yml" >> .gitignore
    fi
fi

sed -i '' -e "s/LOCAL_DATABASE_NAME_PLACEHOLDER/$SQL_DATABASE/g" ./RoboLocal.php
sed -i '' -e "s/MYSQL_USERNAME_PLACEHOLDER/$SQL_USERNAME/g" ./RoboLocal.php
sed -i '' -e "s/SITE_MACHINE_NAME_PLACEHOLDER/$SITE_MACHINE_NAME/g" ./RoboLocal.php
sed -i '' -e "s/SITE_ENV_PLACEHOLDER/$SITE_ENV/g" ./RoboLocal.php

if [ ! -z "$SQL_PASSWORD" ]
  then
    sed -i '' -e "s/\/\/ define('ROBO_DB_PASS', 'MYSQL_PASSWORD_PLACEHOLDER');/define('ROBO_DB_PASS', '${SQL_PASSWORD}')/g" ./RoboLocal.php
fi

# In theory everything is set up and ready for robo pull!
robo pull

if [ "${COPY_FILES}" == "yes" ] 
  then
    echo -e "\nThe database is set up, and I'm about to start pulling the files from the $SITE_ENV environment. This can take quite a while, so if you'd like you can start working with the code while the files download :)"
    robo pullfiles
fi






# 1. COLLECT ALL THE VARIABLES
# 2. CREATE THE DATABASE
# 3. CLONE THE SITE
# 4. COPY IN THE APPROPRIATE FILES
# 5. REPLACE THE APPROPRIATE VARIABLES IN THE COPIED FILES
# 6. USE ROBO TO COPY THE DATABASE
# 7. IF DESIRED, USE ROBO TO COPY THE FILES

# TODO: maybe check in settings.php / wp-config.php to see if the local files are being included and add the include if it's not there (some older sites, maybe)