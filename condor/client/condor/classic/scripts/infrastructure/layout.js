/*
 * Provides access to layout related information specified below.
 * Viewport
 *   Application viewport = browsers viewport without application chrome (navbars etc)
 *   See measure function below for actual algorithm used for this calculation.
 *
 * ContentSize
 *   Size of the div used to render page content.
 *
 * */
angular.module('Inprotech.Infrastructure')
    .service('layout', ['$rootScope', '$document',
        function($rootScope, $document) {
            'use strict';
            var self = this;

            var zero = function() {
                return 0;
            };

            var emptyElement = {
                outerWidth: zero,
                outerHeight: zero
            };

            var measure = function() {
                var branding = ($document.find('#topheader') || emptyElement).outerHeight(true);
                var bottom = (emptyElement).outerHeight(true);
                var left = ($document.find('#leftBar') || emptyElement).outerWidth(true);
                var top = bottom + branding;

                //clientWidth and clientHeight don't account for scrollbar.
                return {
                    top: top,
                    left: left,
                    width: $document[0].documentElement.clientWidth - left,
                    height: $document[0].documentElement.clientHeight - top
                };
            };

            self.contentSize = function() {
                var contentElement = $document.find('#mainContent');
                return {
                    width: contentElement.outerWidth(true),
                    height: contentElement.outerHeight(true)
                };
            };

            self.detectViewportChanges = function() {
                var newViewport = measure();

                if (self.viewport.width === newViewport.width &&
                    self.viewport.height === newViewport.height) {
                    return;
                }

                if (self.viewport.height !== newViewport.height) {
                    $('#mainPane').height(newViewport.height);
                }
                self.viewport = newViewport;
                $rootScope.$broadcast('viewportResize', self.viewport);
            };

            self.viewport = measure();
        }
    ]);