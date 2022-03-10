describe('Inprotech.BulkCaseImport.batchSummaryController', function() {
    'use strict';

    var _scope, _batch, _controller, _bulkCaseImportService, localSettings, kendoGridBuilder;

    beforeEach(function() {
        module('Inprotech.BulkCaseImport')
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.bulkcaseimport', 'inprotech.mocks.core', 'inprotech.mocks']);
            _bulkCaseImportService = $injector.get('importStatusServiceMock');
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            localSettings = $injector.get('localSettingsMock');
            localSettings.Keys.caseImport.batchSummary.pageNumber.setLocal(50);
            $provide.value('kendoGridBuilder', kendoGridBuilder);
            $provide.value('bulkCaseImportService', _bulkCaseImportService);
        });
    });

    beforeEach(inject(function($rootScope, $controller) {
        _scope = $rootScope.$new();
        _batch = {
            id: '100',
            name: '200',
            transReturnCode: 'isCanceled'
        };

        _controller = function() {
            return $controller('batchSummaryController', {
                '$scope': _scope,
                'batch': _batch,
                'localSettings': localSettings
            });
        };
    }));

    describe('onInit', function() {
        it('create gridopion', function() {
            var c = _controller();  
            c.$onInit();
            expect(c.gridOptions).toBeDefined();
        });
    })

    describe('Produce Inprotech Link', function() {
        it('should be able to link to Inprotech', function() {
            var c = _controller();
            c.$onInit();
            var inproLink = c.gotoInprotech('SomePath');
            expect(inproLink).toBe('../default.aspx?caseref=SomePath');
        });
    })
});