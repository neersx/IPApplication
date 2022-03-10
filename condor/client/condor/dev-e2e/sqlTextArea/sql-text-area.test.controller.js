angular.module('inprotech.deve2e').controller('SQLTextAreaTestController', function() {
    'use strict';
    var vm = this;
    vm.validData = model();
    
    function model(value) {
        return {
            value: value || '',
            isReadOnly: false
        };
    }
});

