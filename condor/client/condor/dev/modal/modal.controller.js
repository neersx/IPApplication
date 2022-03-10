angular.module('inprotech.dev').controller('DevModalController', function(modalService) {
    'use strict';

    var vm = this;
    vm.openNav = function() {
        modalService.openModal({
            templateUrl: 'condor/dev/modal/navigation.html',
            controller: 'DevModalNavController',
            currentItem: 'Item A',
            allItems: ['Item A', 'Item B', 'Item C'],
            isSingleton: false
        })
    };
}).controller('DevModalNavController', function($scope, options) {
    var vm = this;
    vm.options = options;
    vm.onNavigate = function(newItem) {
        $scope.$emit('modalChangeView', {
            currentItem: newItem
        });
    };
});
