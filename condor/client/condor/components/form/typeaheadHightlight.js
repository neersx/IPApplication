angular.module('inprotech.components.form').filter('ipTypeaheadHighlight', ['$sce', '$injector', '$log', function($sce, $injector, $log) {
    'use strict';
    var isSanitizePresent;
    isSanitizePresent = $injector.has('$sanitize');

    function escapeRegexp(queryToEscape) {
        // Regex: capture the whole query string and replace it with the string that will be used to match
        // the results, for example if the capture is "a" the result will be \a
        return queryToEscape.replace(/([.?*+^$[\]\\(){}|-])/g, '\\$1');
    }

    function containsHtml(matchItem) {
        return /<.*>/g.test(matchItem);
    }

    return function(matchItem, query) {
        if(matchItem == null) {
            matchItem = null;
        } else {
            matchItem = matchItem.toString();
        }

        if (!isSanitizePresent && containsHtml(matchItem)) {
            $log.warn('Unsafe use of typeahead please use ngSanitize'); // Warn the user about the danger
        }
        matchItem = query ? ('' + matchItem).replace(new RegExp(escapeRegexp(query), 'gi'), '<strong>$&</strong>') : matchItem; // Replaces the capture string with a the same string inside of a "strong" tag

        if (!isSanitizePresent) {
            matchItem = $sce.trustAsHtml(matchItem); // If $sanitize is not present we pack the string in a $sce object for the ng-bind-html directive
        }

        return matchItem;
    };
}]);
