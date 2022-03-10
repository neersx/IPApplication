angular.module('inprotech.components', [
    'ui.bootstrap',
    'inprotech.api',
    'inprotech.components.buttons',
    'inprotech.components.tooltip',
    'inprotech.components.picklist',
    'inprotech.components.bulkactions',
    'inprotech.components.messaging',
    'inprotech.components.typeahead',
    'inprotech.components.searchOptions',
    'inprotech.components.notification',
    'inprotech.components.focus',
    'inprotech.components.page',
    'inprotech.components.kendo',
    'inprotech.components.grid',
    'inprotech.components.tree',
    'inprotech.components.barchart',
    'inprotech.components.sort',
    'inprotech.components.keypressevent',
    'inprotech.components.form',
    'inprotech.components.topics',
    'inprotech.components.login',
    'inprotech.components.modal',
    'inprotech.components.panel',
    'inprotech.components.splitter',
    'inprotech.components.menu',
    'inprotech.components.stateContext',
    'ngTagsInput',
    'pascalprecht.translate',
    'inprotech.components.multistepsearch'
]).config(function($translateProvider) {
    'use strict';
    $translateProvider.useSanitizeValueStrategy('escapeParameters');
});