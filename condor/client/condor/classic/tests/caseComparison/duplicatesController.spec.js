'use strict';

describe('Inprotech.CaseDataComparison.duplicatesController', function() {

    var fixture = { forId: 10, duplicateCases: [], scopeData: {} };
    var rootScope = null;

    beforeEach(module('Inprotech.CaseDataComparison'));

    beforeEach(inject(function($controller, $rootScope) {
        rootScope = $rootScope;
        fixture = {
            controller: function() {
                fixture.scope = angular.extend($rootScope.$new(), fixture.scopeData);
                var cntr = $controller('duplicatesController', {
                    $scope: fixture.scope,
                    viewInitialiser: {
                        viewData: {
                            canUpdateCase: true,
                            duplicates: fixture.duplicateCases
                        }
                    },
                    $stateParams: {
                        forId: fixture.forId
                    }
                });
                fixture.scope.init();
                return cntr;
            },
            viewView: {}
        };
    }));

    it('ensure notification in question is displayed as first notification', function() {
        fixture.duplicateCases = [{ notificationId: 9 }, { notificationId: 90 }, { notificationId: 11 }, { notificationId: 12 }];
        fixture.forId = 11;

        fixture.controller();

        expect(_.first(fixture.scope.duplicates).notificationId).toBe(fixture.forId);
    });

    it('broadcasts to display first notification on init', function() {
        var selectedNotification = { notificationId: 10, type: 'sometype' };
        fixture.duplicateCases = [selectedNotification, { notificationId: 90 }];
        fixture.scopeData = {
            $broadcast: jasmine.createSpy()
        };

        fixture.controller();

        expect(fixture.scope.$broadcast).toHaveBeenCalledWith(selectedNotification.type, selectedNotification);
    });

    it('does not navigate next on case-match-rejection-reversed, displays data', function() {
        var selectedNotification = { notificationId: 10, type: 'sometype' };
        var nextNotification = { notificationId: 90, type: 'someOthertype' };
        fixture.duplicateCases = [selectedNotification, nextNotification];
        fixture.scopeData = {
            $broadcast: jasmine.createSpy()
        };

        fixture.controller();

        selectedNotification.type = 'Not rejected';
        rootScope.$broadcast('case-match-rejection-reversed', selectedNotification);

        expect(fixture.scope.$broadcast).toHaveBeenCalledWith('Not rejected', selectedNotification);
    });
});