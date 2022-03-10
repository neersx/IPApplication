angular.module('inprotech.components.page').component('ipResizeHandlerWrapper', {
    transclude: true,
    template: '<div ip-resize-handler resize-handler-type="Panel"><ng-transclude></ng-transclude></div>'
});