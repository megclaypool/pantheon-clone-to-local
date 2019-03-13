<?php

// Local development configuration.
if (!defined('PANTHEON_ENVIRONMENT')) {
  // Database.
  $databases['default']['default'] = array(
    'database' => 'LOCAL_DATABASE_NAME_PLACEHOLDER',
    'username' => 'MYSQL_USERNAME_PLACEHOLDER',
    'password' => 'MYSQL_PASSWORD_PLACEHOLDER',
    'host' => 'localhost',
    'driver' => 'mysql',
    'port' => 3306,
    'prefix' => '',
  );

  
  $conf['file_temporary_path'] = '/tmp';
  $conf['theme_debug'] = TRUE;

  ini_set('session.gc_maxlifetime', 0);
  ini_set('session.cookie_lifetime', 0);
  
/**
 * Disable CSS and JS aggregation.
 */
  $conf['preprocess_css'] = FALSE;
  $conf['preprocess_js'] = FALSE;
  
/**
 * Disable/bypass the Drupal Render API cache
 */
  $settings['cache']['bins']['render'] = 'cache.backend.null';
}

/** 
 * Error Logging
 */
// error_reporting(E_ALL);
// ini_set('display_errors', TRUE);
// ini_set('display_startup_errors', TRUE);
// $config['system.logging']['error_level'] = 'verbose';

