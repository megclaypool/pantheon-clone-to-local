# pantheon-clone-to-local
Clone a Pantheon site (WordPress, Drupal 7, or Drupal 8) to your local, including automatic setup of database and (if desired) files.

# System Prerequisites
1.   mysql or mariadb
2.   [terminus](https://pantheon.io/docs/terminus/install/)
3.   [robo](https://robo.li/)

# Info you'll need
1.   Your site's machine name on Pantheon. (You can find the machine name of your site by visiting the site's Pantheon dashboard and clicking the tab for the dev environment. Then click the "Visit Development Site" button. The site's machine name is the bit between "dev-" and ".pantheonsite.io" in the url.)
2.   Which environment (live, dev, some multidev?) you'd like to clone the database from
3.   The username and password for your local mysql

# How To
1.   Clone this project to your local. (Either put it in your Sites directory (or projects or whatever you call it) or add an alias to the script in your bash profile to make it easier to call.)
2.   You can either edit the script and fill in the variables at the top or just run it and input the variables in the interactive wizard.
3.   The automatic detection of which kind of site (WordPress, Drupal 7, or Drupal 8) is based on Pantheon upstreams, and includes some custom upstreams. You may need to edit the script to include any of your own custom upstreams.
