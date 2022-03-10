angular.module('inprotech.mocks').factory('transitionsMock', function() {
    'use strict';

    var onStartUnbindSpy = jasmine.createSpy();
    var onSuccessUnbindSpy = jasmine.createSpy();

    var executeCallBackFor = function(hook, testId, param1, param2) {
        var callInstance = _.find(r[hook].calls.all(), function(c) { return c.args[0].testId === testId; });
        if (callInstance) {
            callInstance.args[1](param1, param2);
        }
    }

    var r = {
        onStartUnbindSpy: onStartUnbindSpy,
        onSuccessUnbindSpy: onSuccessUnbindSpy,
        onStart: jasmine.createSpy().and.returnValue(onStartUnbindSpy),
        onSuccess: jasmine.createSpy().and.returnValue(onSuccessUnbindSpy),
        onEnter: jasmine.createSpy(),
        onExit: jasmine.createSpy(),
        onBefore: jasmine.createSpy(),
        onError: jasmine.createSpy(),
        executeCallBackFor: executeCallBackFor,
        onRetain: jasmine.createSpy()
    };

    return r;
});