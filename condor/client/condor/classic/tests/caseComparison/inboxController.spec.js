'use strict';

describe('Inprotech.CaseDataComparison.inboxController', function() {

    beforeEach(module('Inprotech.CaseDataComparison'));

    var fixture = {};
    var dataSources = [{
        id: 'UsptoPrivatePair',
        count: 10
    }, {
        id: 'UsptoTsdr',
        count: 1,
        dmsIntegrationEnabled: true
    }, {
        id: 'Epo',
        count: 20
    }, {
        id: 'Innography',
        count: 1
    }];

    var notifications = [{
        type: 'case-comparison',
        notificationId: 1,
        dataSource: 'UsptoTsdr',
        title: 'TITLE',
        appNum: '61389191',
        caseRef: '1234/a',
        caseId: -487,
        date: 'now'
    }, {
        type: 'case-comparison',
        notificationId: 2,
        dataSource: 'UsptoPrivatePair',
        title: 'MECHANISMS',
        appNum: 'PCT/US10/46075',
        caseId: -505,
        isReviewed: true,
        date: 'now'
    }, {
        type: 'rejected',
        notificationId: 2,
        dataSource: 'Innography',
        title: 'Rejected item',
        appNum: 'PCT/US10/46075',
        caseId: -506,
        isReviewed: true,
        date: 'now'
    }, {
        type: 'error',
        notificationId: 3,
        caseId: null,
        appNum: '19999999',
        caseRef: null,
        dataSource: 'UsptoPrivatePair',
        title: 'Error',
        body: [],
        date: 'now'
    }];

    beforeEach(
        inject(
            function($controller, $rootScope, $injector) {

                var httpBackend = $injector.get('$httpBackend');

                fixture = {
                    stateParams: { restore: false },
                    httpBackend: httpBackend,
                    controller: function() {
                        fixture.scope = $rootScope.$new();
                        fixture.inboxState = fixture.inboxState || {};
                        return $controller('inboxController', {
                            $stateParams: fixture.stateParams,
                            $scope: angular.extend(fixture.scope, fixture.scopeData || {}),
                            inboxState: fixture.inboxState,
                            viewInitialiser: {
                                viewData: {
                                    canUpdateCase: true
                                }
                            }
                        });
                    },
                    viewView: {}
                };
            }
        )
    );

    afterEach(function() {
        fixture.httpBackend.verifyNoOutstandingExpectation();
        fixture.httpBackend.verifyNoOutstandingRequest();
    });

    var doFirstCall = function(notificationsToBeReceieved, hasMore) {
        fixture.httpBackend.whenPOST('api/casecomparison/inbox/notifications')
            .respond({
                dataSources: dataSources,
                notifications: notifications,
                hasMore: hasMore
            });

        fixture.controller();
        fixture.httpBackend.flush();
    };

    it('should load more notifications', function() {

        doFirstCall(notifications, true);

        expect(fixture.scope.notifications.length).toBe(4);

        fixture.httpBackend.whenPOST('api/casecomparison/inbox/notifications')
            .respond({
                dataSources: null,
                notifications: notifications,
                hasMore: false
            });

        fixture.scope.loadData();
        fixture.httpBackend.expectPOST('api/casecomparison/inbox/notifications');
        fixture.httpBackend.flush();

        expect(fixture.scope.notifications.length).toBe(8);
    });

    it('should stop at the last page', function() {
        doFirstCall(notifications, true);

        expect(fixture.scope.notifications.length).toBe(4);

        fixture.httpBackend.whenPOST('api/casecomparison/inbox/notifications')
            .respond({
                dataSources: null,
                notifications: notifications,
                hasMore: false
            });

        fixture.scope.loadData();
        fixture.httpBackend.expectPOST('api/casecomparison/inbox/notifications');
        fixture.httpBackend.flush();

        expect(fixture.scope.hasMore, false);
    });

    it('should update view to selected notification', function() {

        doFirstCall(notifications, false);
        var n = {
            type: 'new-case'
        };
        fixture.scope.showView(n);
        expect(fixture.scope.detailView).toBe(n);
    });

    it('should update notification with dms is enabled', function() {
        doFirstCall(notifications, false);
        var n = {
            type: 'case-comparison',
            dataSource: 'UsptoTsdr'
        };

        spyOn(fixture.scope, '$broadcast');

        fixture.scope.showView(n);

        expect(fixture.scope.$broadcast.calls.mostRecent().args[1]).toEqual(_.extend(n, {
            dmsIntegrationEnabled: true
        }));
    });

    it('should return available data sources', function() {
        doFirstCall(notifications, false);
        expect(fixture.scope.dataSources.length).toBe(4);
        expect(_.first(fixture.scope.dataSources).isSelected).toBe(false);
    });

    it('should mark data source as deselected if its filtered out', function() {
        doFirstCall(notifications, false);
        fixture.scope.filteringChanged(_.first(fixture.scope.dataSources));
        expect(_.first(fixture.scope.dataSources).isSelected).toBe(true);

        fixture.httpBackend.expectPOST('api/casecomparison/inbox/notifications', '{"pageSize":50,"since":"","dataSourceTypes":["UsptoPrivatePair"],"includeReviewed":false,"includeErrors":false,"includeRejected":false,"searchText":""}').respond({
            dataSources: null,
            notifications: notifications,
            hasMore: false
        });

        fixture.httpBackend.flush();
    });

    it('should filter out error if includeError check box is set to false', function() {
        doFirstCall(notifications, false);
        fixture.scope.filterParams.includeErrors = false;

        fixture.scope.inclusionChanged();

        fixture.httpBackend.expectPOST('api/casecomparison/inbox/notifications', '{"pageSize":50,"since":"","dataSourceTypes":["UsptoPrivatePair","UsptoTsdr","Epo","Innography"],"includeReviewed":false,"includeErrors":false,"includeRejected":false,"searchText":""}').respond({
            dataSources: null,
            notifications: notifications,
            hasMore: false
        });

        fixture.httpBackend.flush();
    });

    it('should display errors if includeError check box is set to true', function() {
        doFirstCall(notifications, false);
        fixture.scope.filterParams.includeErrors = true;

        fixture.scope.inclusionChanged();

        fixture.httpBackend.expectPOST('api/casecomparison/inbox/notifications', '{"pageSize":50,"since":"","dataSourceTypes":["UsptoPrivatePair","UsptoTsdr","Epo","Innography"],"includeReviewed":false,"includeErrors":true,"includeRejected":false,"searchText":""}').respond({
            dataSources: null,
            notifications: notifications,
            hasMore: false
        });

        fixture.httpBackend.flush();
    });

    it('should filter out reviewed notifications if includeReviewed check box is set to false', function() {
        doFirstCall(notifications, false);
        fixture.scope.filterParams.includeReviewed = false;

        fixture.scope.inclusionChanged();

        fixture.httpBackend.expectPOST('api/casecomparison/inbox/notifications', '{"pageSize":50,"since":"","dataSourceTypes":["UsptoPrivatePair","UsptoTsdr","Epo","Innography"],"includeReviewed":false,"includeErrors":false,"includeRejected":false,"searchText":""}').respond({
            dataSources: null,
            notifications: notifications,
            hasMore: false
        });

        fixture.httpBackend.flush();
    });

    it('should display reviewed notifications if includeReviewed check box is set to true', function() {
        doFirstCall(notifications, false);
        fixture.scope.filterParams.includeReviewed = true;

        fixture.scope.inclusionChanged();

        fixture.httpBackend.expectPOST('api/casecomparison/inbox/notifications', '{"pageSize":50,"since":"","dataSourceTypes":["UsptoPrivatePair","UsptoTsdr","Epo","Innography"],"includeReviewed":true,"includeErrors":false,"includeRejected":false,"searchText":""}').respond({
            dataSources: null,
            notifications: notifications,
            hasMore: false
        });

        fixture.httpBackend.flush();
    });

    it('should filter out rejected case match notifications if includeRejected check box is set to false', function() {
        doFirstCall(notifications, false);
        fixture.scope.filterParams.includeRejected = false;

        fixture.scope.inclusionChanged();

        fixture.httpBackend.expectPOST('api/casecomparison/inbox/notifications', '{"pageSize":50,"since":"","dataSourceTypes":["UsptoPrivatePair","UsptoTsdr","Epo","Innography"],"includeReviewed":false,"includeErrors":false,"includeRejected":false,"searchText":""}').respond({
            dataSources: null,
            notifications: notifications,
            hasMore: false
        });

        fixture.httpBackend.flush();
    });

    it('should display rejected case match notifications if includeRejected check box is set to true', function() {
        doFirstCall(notifications, false);
        fixture.scope.filterParams.includeRejected = true;

        fixture.scope.inclusionChanged();

        fixture.httpBackend.expectPOST('api/casecomparison/inbox/notifications', '{"pageSize":50,"since":"","dataSourceTypes":["UsptoPrivatePair","UsptoTsdr","Epo","Innography"],"includeReviewed":false,"includeErrors":false,"includeRejected":true,"searchText":""}').respond({
            dataSources: null,
            notifications: notifications,
            hasMore: false
        });

        fixture.httpBackend.flush();
    });

    it('should attempt to restore saved state, if restore indicated', function() {
        var returnData = {
            notifications: [{ notificationId: 1 }, { notificationId: 5 }],
            dataSources: [],
            filterParams: {},
            notificationIdToSelect: 5,
            hasMore: false
        };

        fixture.inboxState = {
            pop: jasmine.createSpy().and.returnValue(returnData)
        };

        fixture.stateParams.restore = true;
        fixture.scopeData = {
            $broadcast: jasmine.createSpy()
        };
        fixture.controller();

        expect(fixture.inboxState.pop).toHaveBeenCalled();
        expect(fixture.scope.notifications).toEqual(returnData.notifications);
        expect(fixture.scope.dataSources).toEqual(returnData.dataSources);
    });

    it('saves state while navigating to duplicate view', function() {
        fixture.inboxState = {
            save: jasmine.createSpy()
        };

        doFirstCall(notifications, false);

        fixture.scope.onNavigateToDuplicateView();

        var args = fixture.inboxState.save.calls.mostRecent().args;

        var expectedNotifications = angular.copy(notifications);
        expectedNotifications[0] = angular.extend(_.first(expectedNotifications), { dmsIntegrationEnabled: true });

        var expectedDataSources = _.each(dataSources, function(n) {
            return angular.extend(n, { isSelected: false });
        });

        expect(args[0]).toEqual(expectedNotifications);
        expect(args[1]).toEqual(expectedDataSources);
        expect(args[2]).toEqual(fixture.scope.filterParams);
        expect(args[3]).toEqual(fixture.scope.detailView);
        expect(args[4]).toEqual(fixture.scope.hasMore);
    });
});