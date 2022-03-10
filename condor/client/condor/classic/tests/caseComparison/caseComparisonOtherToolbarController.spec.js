'use strict';

describe('Inprotech.CaseDataComparison.caseComparisonOtherToolbarController', function() {

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
                        fixture.rootScope = $rootScope;
                        return $controller('caseComparisonOtherToolbarController', {
                            $rootScope: fixture.rootScope,
                            $location: $location,
                            $scope: fixture.scope,
                            comparisonData: _comparisonData
                        });
                    }
                };
            }
        )
    );

    afterEach(function() {
        fixture.httpBackend.verifyNoOutstandingExpectation();
        fixture.httpBackend.verifyNoOutstandingRequest();
    });

    it('should be saveable', function() {
        _comparisonData = _.extend({
            saveable: function() {
                return true;
            },
            updateable: function() {
                return true;
            }
        });

        fixture.controller();

        expect(fixture.scope.saveable()).toBe(true);
    });

    it('should be saveable', function() {
        _comparisonData = _.extend({
            updateable: function() {
                return true;
            }
        });

        fixture.controller();

        expect(fixture.scope.updateable()).toBe(true);
    });

    it('should only allow reject if it is updatable and rejectable', function() {
        _comparisonData = _.extend({
            updateable: function() {
                return true;
            },
            rejectable: function() {
                return true;
            }
        });

        fixture.controller();

        fixture.scope.notification = {};

        expect(fixture.scope.canRejectMatch()).toBe(true);
    });

    it('should call reject case match api', function() {
        _comparisonData = _.extend({
            updateable: function() {
                return true;
            },
            rejectable: function() {
                return true;
            }
        });

        fixture.controller();

        fixture.scope.notification = {
            notificationId: 25,
            type: 'something'
        };

        fixture.httpBackend.whenPOST('api/casecomparison/inbox/reject-case-match?notificationId=25')
            .respond(function() {
                return [200, {}];
            });

        fixture.scope.rejectCaseMatch();

        fixture.httpBackend.expectPOST('api/casecomparison/inbox/reject-case-match?notificationId=25');
        fixture.httpBackend.flush();
    });

    it('should call reverse reject case match api', function() {
        _comparisonData = _.extend({
            updateable: function() {
                return true;
            },
            rejectable: function() {
                return true;
            }
        });

        fixture.controller();

        fixture.scope.notification = {
            notificationId: 25,
            type: 'rejected'
        };

        fixture.httpBackend.whenPOST('api/casecomparison/inbox/reverse-case-match-rejection?notificationId=25')
            .respond(function() {
                return [200, {}];
            });

        fixture.scope.undoRejectCaseMatch();

        fixture.httpBackend.expectPOST('api/casecomparison/inbox/reverse-case-match-rejection?notificationId=25');
        fixture.httpBackend.flush();
    });
});