<?php

require __DIR__ . '/model/tmp_micka_lib.php';
require __DIR__ . '/../vendor/autoload.php';
$configurator = new Nette\Configurator;

$configurator->setDebugMode('194.228.20.200'); // enable for your remote IP
$configurator->enableTracy(__DIR__ . '/../log');

$configurator->setTimeZone('Europe/Prague');
$configurator->setTempDirectory(__DIR__ . '/../temp');

$configurator->createRobotLoader()
	->addDirectory(__DIR__)
	->register();

$configurator->addConfig(__DIR__ . '/config/config.neon');
$configurator->addConfig(__DIR__ . '/config/config.local.neon');

$container = $configurator->createContainer();

return $container;
