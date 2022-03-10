angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowStatusServiceMock', function() {
    'use strict';

    var mockObject = {
        validStatusQuery: jasmine.createSpy(),
        caseStatusQuery: jasmine.createSpy(),
        renewalStatusQuery: jasmine.createSpy(),
        validCombination: {}
    };

    var init = jasmine.createSpy().and.returnValue(mockObject)

    return init;
});
 