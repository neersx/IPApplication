angular.module('inprotech.deve2e').controller('DetailPageTestController', function() {
    'use strict';

    var vm = this;
    vm.isDirty = function(){
        return vm.form.$dirty;
    };
});