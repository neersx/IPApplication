 'use strict';

 angular.module('Inprotech')
     .factory('focus', ['$timeout', function($timeout) {
         return function(id) {


             // timeout makes sure that it is invoked after any other event has been triggered.
             // e.g. click events that need to run before the focus or
             // inputs elements that are in a disabled state but are enabled when those events
             // are triggered.
             $timeout(function() {
                 var element = document.getElementById(id);
                 if (element) {
                     element.focus();
                 }
             });
         };
     }])
     .directive('inFocusElement', ['focus', function(focus) {
         return function(scope, element, attr) {
             element.on(attr.inFocusElement, function() {
                 focus(attr.focusElementId);
             });

             // Removes bound events in the element itself
             // when the scope is destroyed
             scope.$on('$destroy', function() {
                 element.off(attr.inFocusElement);
             });
         };
     }]);
