angular.module('inprotech.dev').controller('SQLTextAreaController', ['$scope', function ($scope) {
    'use strict';
    $scope.editorOptions = {
        mode: 'text/x-sql',
        theme: 'ssms'
    };
    var vm = this;
    vm.validData = model();
    vm.validDataReadOnly = makeReadOnly(model());

    function model(value) {
        return {
            value: value || 'SELECT * FROM TableOne WHERE TableOne.Name < \'Andy\'',
            isReadOnly: false
        };
    }

    function makeReadOnly(o) {
        o.isReadOnly = true;
        return o;
    }
}]);

