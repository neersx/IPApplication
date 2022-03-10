angular.module('inprotech.components.searchOptions').directive('ipSearchOptionsHeader', function() {
    'use strict';

    return {
        restrict: 'E',
        scope: true,
        templateUrl: 'condor/components/searchoptions/header.html',
        link: function(scope, element) {
            scope.toggleCollapse = function() {
                var searchBody = $('#searchBody');
                var scrollTop = $(window).scrollTop(); // window.scrollTop for cross browser getter
                if (scrollTop >= searchBody.height() + searchBody.offset().top) {
                    searchBody.collapse('show');
                    element.find('a.btn').removeClass('collapsed');

                    // needs to use html, body for cross browser setter with animate
                    $('#mainPane').animate({
                        scrollTop: 0
                    }, 100);
                } else {
                    searchBody.collapse('toggle');
                    element.find('a.btn').toggleClass('collapsed');
                }
            };
        }
    };
});