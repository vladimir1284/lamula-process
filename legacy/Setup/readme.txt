
McGill (.dat)
=============

Las observaciones del radar del Observatorio Marshall existen en dos formatos: compactado (vscan) o descompactado (cscan) en ambos casos la extension del archivo es '.dat'. 

Normalmente un archivo contiene varias observaciones volumetricas independientes, una a continuacion de la otra. Para poder interpretar estas observaciones en el sistema Vesta, es necesario separarlas en archivos individuales. Para este fin puede ser utilizado el utilitario 'SplitDat.exe' que se encuentra en directorio Tools.


DR (.i&o)
=========

Las observaciones grabadas con el antiguo sistema DR en el radar de Casablanca (extension 'I&O'), se guardan en formato LZW compactado. Para utilizar estas observaciones en el sistema de procesamiento Vesta es necesario descompactarlas y cambiarles la extension '.I&O' por '.drf'. Esto puede lograrse con el utilitario 'i&o-dat.exe' presente en el directorio Tools.

Por ejemplo, para utilizar la grabacion DR 'andrew.i&o' debera ejecutarse:

C:\Vesta\Tools\i&o-dat.exe x andrew.i&o andrew.drf

El archivo 'andrew.drf' contendra informacion descompactada que puede ser leida directamente por el sistema Vesta.
