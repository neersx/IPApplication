angular.module('inprotech.mocks')
    .factory('maintenanceModalServiceMock',
    function () {
        'use strict';

        var mock = jasmine.createSpyObj('maintenanceModalServiceMock', ['applyChanges']);

        var constructor = jasmine.createSpy('spy', function(){
            return mock;
        }).and.callThrough();

        return constructor;
    });
