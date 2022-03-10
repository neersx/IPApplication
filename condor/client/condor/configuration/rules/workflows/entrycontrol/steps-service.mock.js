angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowsEntryControlStepsServiceMock', function() {
    'use strict';

    var r = {
        translateStepCategory: jasmine.createSpy(),
        getSteps: jasmine.createSpy(),
        checkStepCategories: jasmine.createSpy(),
        areStepsSame: jasmine.createSpy()
    };

    return r;
});
