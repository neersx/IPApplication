describe('inprotech.processing.policing.policingRequestAffectedCasesService', function() {
    'use strict';

    var service, messageBroker;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.core']);

            messageBroker = $injector.get('messageBrokerMock');
            $provide.value('messageBroker', messageBroker);
        });
    });

    beforeEach(inject(function(policingRequestAffectedCasesService) {
        service = policingRequestAffectedCasesService;
    }));


    describe('Affected Cases', function() {

        it('should subscribe get affected cases', function() {
            var requestId=1;
            service.getAffectedCases(requestId);

            expect(messageBroker.disconnect).toHaveBeenCalled();
            expect(messageBroker.connect).toHaveBeenCalled();
            expect(messageBroker.subscribe).toHaveBeenCalled();

            expect(messageBroker.subscribe.calls.first().args[0]).toBe('policing.affected.cases.' + requestId);            
        });

        it('should get disconnected after receiving response', function() {
            var requestId=1;
            service.getAffectedCases(requestId);

            expect(messageBroker.disconnect).toHaveBeenCalled();
            expect(messageBroker.connect).toHaveBeenCalled();
            expect(messageBroker.subscribe).toHaveBeenCalled();
            
            expect(messageBroker.disconnect.calls.count()).toBe(2);
        });
        
    });
});