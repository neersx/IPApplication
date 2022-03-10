'use strict';

describe('Inprotech.CaseDataComparison.availableDocumentsController', function() {
    var fixture = {};

    beforeEach(function() {
        var modalService;
        var notificationService;

        module('Inprotech.CaseDataComparison');
        module(function() {
            modalService = test.mock('modalService');
            notificationService = test.mock('notificationService');
        });

        inject(function($controller, $rootScope, comparisonDataSourceMap, $q) {
            fixture = {
                modalService: modalService,
                notificationService: notificationService,
                comparisonDataSourceMap: comparisonDataSourceMap,
                scope: $rootScope.$new,
                $q: $q,
                controller: function() {
                    fixture.scope = $rootScope.$new();
                    return $controller('availableDocumentsController', {
                        modalService: modalService,
                        notificationService: notificationService,
                        comparisonDataSourceMap: comparisonDataSourceMap,
                        $scope: fixture.scope
                    });
                }
            };
        });
    });

    it('displays import document dialog', function() {
        fixture.controller();
        fixture.scope.caseId = 999;

        var document = { somedoc: 'something' };
        fixture.scope.importDocument(document);

        expect(fixture.modalService.open).toHaveBeenCalled();
        expect(fixture.modalService.open.calls.mostRecent().args[0]).toEqual('ImportDocument');
        var documentToImport = fixture.modalService.open.calls.mostRecent().args[2].documentToImport();
        expect(documentToImport.caseId).toEqual(fixture.scope.caseId);
        expect(documentToImport.document).toEqual(document);
    });

    it('should display successful message on successful import', function() {
        fixture.modalService.open = jasmine.createSpy().and.returnValue(fixture.$q.when('success'));
        fixture.controller();
        fixture.scope.caseId = 999;

        var document = { somedoc: 'something' };
        fixture.scope.importDocument(document);

        fixture.scope.$apply();

        expect(fixture.notificationService.success).toHaveBeenCalled();
        expect(fixture.scope.documentToImport).toBe(null);
    });
});