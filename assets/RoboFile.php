<?php
/**
 * This is project's console commands configuration for Robo task runner.
 *
 * @see http://robo.li/
 */
 
if (file_exists(dirname(__FILE__) . '/RoboLocal.php') && !isset($_ENV['PANTHEON_ENVIRONMENT'])):
  include(dirname(__FILE__) . '/RoboLocal.php');
endif;
 
class RoboFile extends \Robo\Tasks {
    /**
     * Gets the database from Pantheon.
     */
    function pull() {
        $env = ROBO_SITENAME . '.' . ROBO_ENV;
 
        $this->say('Creating backup on Pantheon.');
        $this->taskExec('terminus')->args('backup:create', $env, '--element=db')->run();
        $this->say('Downloading backup file.');
        $this->taskExec('terminus')->args('backup:get', $env, '--to=db.sql.gz', '--element=db')->run();
        $this->say('Unzipping and importing data');
 
        $mysql = "mysql";
        if(defined('ROBO_DB_USER')) {
          $mysql .= " -u " . ROBO_DB_USER;
        }
        if(defined('ROBO_DB_PASS')) {
          $mysql .= " -p" . ROBO_DB_PASS;
        }
        $mysql .= ' ' . ROBO_DB;
 
        $this->_exec('gunzip < db.sql.gz | ' . $mysql);
 
        $this->say('Data Import complete, deleting db file.');
        $this->_exec('rm db.sql.gz');
    }
 
    function pullfiles() {
        $env = ROBO_SITENAME . '.' . ROBO_ENV;
        $download = 'files_' . ROBO_ENV;
 
        $this->say('Creating files backup on Pantheon.');
        $this->taskExec('terminus')->args('backup:create', $env, '--element=files')->run();
        $this->say('Downloading files.');
        $this->taskExec('terminus')->args('backup:get', $env, '--to=files.tar.gz', '--element=files')->run();
        $this->say('Unzipping archive');
        $this->taskExec('tar')->args('-xvf', './files.tar.gz')->run();
        $this->say('Copying Files');
        $this->_copyDir($download, ROBO_FILES_DIR);
 
        $this->say('Removing downloaded Files.');
        $this->_exec("rm -rf ./$download");
        $this->_exec('rm ./files.tar.gz');
    }
}