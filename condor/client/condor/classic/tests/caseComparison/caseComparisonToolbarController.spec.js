'use strict';

describe('Inprotech.CaseDataComparison.caseComparisonToolbarController', function() {

    beforeEach(module('Inprotech.CaseDataComparison'));

    var fixture = {};
    var _comparisonData = {};

    beforeEach(
        inject(
            function($controller, $rootScope, $location, $injector) {
                var httpBackend = $injector.get('$httpBackend');
                var newScope = $rootScope.$new();
                fixture = {
                    location: $location,
                    httpBackend: httpBackend,
                    controller: function() {
                        fixture.scope = newScope;
                        return $controller('caseComparisonToolbarController', {
                            $location: $location,
                            $scope: fixture.scope,
                            comparisonData: _comparisonData
                        });
                    }
                };
            }
        )
    );

     it('should be saveable', function() {
        _comparisonData = _.extend({
            saveable: function() {
                return true;
            }
        });

        fixture.controller();

        expect(fixture.scope.saveable()).toBe(true);
    });

    it('should prepare data before send to server to save changes', function() {
        _comparisonData = _.extend({
            saveChanges: function() {}
        });

        var updateCase = spyOn(_comparisonData, 'saveChanges');

        fixture.httpBackend.whenGET('api/casecomparison/n/1/case/2/USPTO.TSDR')
            .respond({
                viewData: {}
            });

        fixture.controller();
        fixture.scope.showView = function() {};
        fixture.scope.saveChanges(fixture.scope);
        expect(updateCase).toHaveBeenCalled();
    });
});
