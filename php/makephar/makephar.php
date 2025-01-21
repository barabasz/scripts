<?php

function is_dir_empty($dir) {
    foreach (new DirectoryIterator($dir) as $fileInfo) {
        if($fileInfo->isDot()) continue;
        return false;
    }
    return true;
}

try {
    if (!array_key_exists(1, $argv)) {
        throw new Exception('No project folder specified!');
    } else {
        $pharFolder = $argv[1];
        $appFolder = 'app';
        $appFolderPath = $pharFolder . '/' . $appFolder;
        $pharFile = 'app.phar';
        $pharFilePath = $pharFolder  . '/' . $pharFile;
        $pharStubFile = 'main.php';
        $pharStubFilePath = $appFolderPath  . '/' . $pharStubFile;
        $pharCompressed = true;
        $pharExecutable = true;
        $pharOverwrite = true;

    }

    if (!is_dir($appFolder)) {
        throw new Exception('No app folder!');
    } elseif (is_dir_empty($appFolder)) {
        throw new Exception('Empty app folder!');
    } elseif (!file_exists($pharStubFilePath)) {
        throw new Exception($appFolder . '/' . $pharStubFile . ' stub file does not exist!');
    } elseif (!is_writable($pharFolder)) {
        throw new Exception('Cannot write to ' . $pharFolder);
    }

    if($pharOverwrite) {
        if (file_exists($pharFile)) {
            unlink($pharFile);
        }
    } else {
        if (file_exists($pharFile)) {
            throw new Exception('File ' . $pharFile . ' already exists!');
        }        
    }

    $phar = new Phar($pharFile);
    $phar->startBuffering();
    $defaultStub = $phar->createDefaultStub($pharStubFile);
    $phar->buildFromDirectory($appFolderPath);
    $stub = "#!/usr/bin/env php \n" . $defaultStub;
    $phar->setStub($stub);
    $phar->stopBuffering();

    if ($pharCompressed) {
        $phar->compressFiles(Phar::GZ);
    }

    if ($pharCompressed) {
        chmod($pharFilePath, 0770);
    }

    echo "$pharFile successfully created" . PHP_EOL;
} catch (Exception $e) {
    echo $e->getMessage() . PHP_EOL;
}
