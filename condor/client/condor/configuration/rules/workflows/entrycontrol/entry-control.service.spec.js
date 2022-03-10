describe('inprotech.configuration.rules.workflows.workflowsEntryControlService', function() {
    'use strict';

    var service, httpMock;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector([
                'inprotech.mocks.configuration.rules.workflows',
                'inprotech.mocks'
            ]);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
        inject(function(workflowsEntryControlService) {
            service = workflowsEntryControlService;
        });
    });

    it('translateDateOption should map attribute to translation key', function() {
        expect(service.translateDateOption(null)).toBe('');
        expect(service.translateDateOption(0)).toBe('workflows.entrycontrol.dateOptions.displayOnly');
        expect(service.translateDateOption(1)).toBe('workflows.entrycontrol.dateOptions.entryMandatory');
        expect(service.translateDateOption(2)).toBe('workflows.entrycontrol.dateOptions.hide');
        expect(service.translateDateOption(3)).toBe('workflows.entrycontrol.dateOptions.entryOptional');
        expect(service.translateDateOption(4)).toBe('workflows.entrycontrol.dateOptions.defaultToSystemDate');
    });

    it('translateControlOption should map attribute to translation key', function() {
        expect(service.translateControlOption(null)).toBe('');
        expect(service.translateControlOption(0)).toBe('workflows.entrycontrol.controlOptions.displayOnly');
        expect(service.translateControlOption(1)).toBe('workflows.entrycontrol.controlOptions.entryMandatory');
        expect(service.translateControlOption(2)).toBe('workflows.entrycontrol.controlOptions.hide');
        expect(service.translateControlOption(3)).toBe('workflows.entrycontrol.controlOptions.entryOptional');
    });

    it('getDetails should pass correct parameters', function() {
        service.getDetails(-1, -2);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/entrycontrol/-2/details');
    });

    it('updateDetail should pass correct parameters', function(){
        var updatedEntry = {description: 'new description'};
        service.updateDetail(100, 5, updatedEntry);
        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/rules/workflows/100/entrycontrol/5', updatedEntry);
    });

    it('dueDateRespOptions should return correct options', function(){
        var options = service.dueDateRespOptions();
        expect(options.length).toBe(3);
        expect(_.findWhere(options, {key:0})).toBeDefined();
        expect(_.findWhere(options, {key:1})).toBeDefined();
        expect(_.findWhere(options, {key:2})).toBeUndefined();
        expect(_.findWhere(options, {key:3})).toBeDefined();
    });
});
