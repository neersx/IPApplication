angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowsEntryControlServiceMock', function() {
    'use strict';

    var r = {
        getDetails: jasmine.createSpy(),
        translateEntryAttribute: jasmine.createSpy(),
        getSteps: jasmine.createSpy(),
        updateDetail: jasmine.createSpy(),
        isDuplicated: jasmine.createSpy(),
        setEditedAddedFlags: jasmine.createSpy(),
        getUsers: angular.noop,
        dueDateRespOptions: angular.noop
    };

    return r;
});
