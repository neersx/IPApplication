 angular.module('inprotech.dev')
     .controller('MenuController', function($scope) {
         $scope.menuOrientation = "vertical";
         $scope.onSelect = function(ev) {
             alert($(ev.item.firstChild).text());
         };
     })