angular.module('inprotech.localisation', [
    'inprotech.core',
    'pascalprecht.translate'
]).config(function($translateProvider) {
    'use strict';
    $translateProvider.useSanitizeValueStrategy('escape');
});
