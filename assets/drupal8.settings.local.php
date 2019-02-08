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
  $config['system.performance']['css']['preprocess'] = FALSE;
  $config['system.performance']['js']['preprocess'] = FALSE;
  
  /**
   * Disable/bypass the Drupal Render API cache
   */
  $settings['cache']['bins']['render'] = 'cache.backend.null';

  
  $settings['hash_salt'] = 'my_random_hash';
  $settings['container_yamls'][] = __DIR__ . '/services.local.yml';
  
  
  /**
   * Set Kint's max levels when using Devel and Kint in Drupal 8:
   */
  require_once DRUPAL_ROOT . '/modules/contrib/devel/kint/kint/Kint.class.php';
  Kint::$maxLevels = 3;
  
  
  /**
  *For Drupal 8 with subfolder install: 
  */
  // $base_url = 'http://site_folder_name.whatever_domain';
  // if (isset($GLOBALS['request']) && '/web/index.php' === $GLOBALS['request']->server->get('SCRIPT_NAME')) {
  //   $GLOBALS['request']->server->set('SCRIPT_NAME', '/index.php');
  // }
}
