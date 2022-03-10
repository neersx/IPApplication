'use strict';

describe('Inprotech.Integration.PtoAccess.schedulesController', function() {

    var fixture = {};
    var kendoGridBuilder, notificationService, modalService, translate;

    beforeEach(
        module(function() {
            kendoGridBuilder = test.mock('kendoGridBuilder');
            modalService = test.mock('modalService');
            notificationService = test.mock('notificationService');
            translate = test.mock('$translate', 'translateMock');
        }));

    beforeEach(module('Inprotech.Integration.PtoAccess'));

    beforeEach(
        inject(
            function($controller, $rootScope, $httpBackend, $location) {

                fixture = {
                    location: $location,
                    httpBackend: $httpBackend,
                    viewData: {
                        schedules: [{
                            id: '1',
                            name: 'Daily status check',
                            runOnDays: 'Sun,Mon,Tue,Wed,Thu,Fri,Sat',
                            downloadType: 'StatusChanges',
                            startTime: '00:00:00'
                        }]
                    },
                    controller: function() {
                        fixture.scope = $rootScope.$new();

                        return $controller('schedulesController', {
                            $scope: fixture.scope,
                            kendoGridBuilder: kendoGridBuilder,
                            notificationService: notificationService,
                            modalService: modalService,
                            $translate: translate
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

    describe('initialise', function() {
        it('should initialise the page,and display the correct columns', function() {
            var c = fixture.controller();
            c.$onInit();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(_.pluck(c.gridOptions.columns, 'title')).toEqual(['dataDownload.schedules.nextRun', 'dataDownload.schedules.description', 'dataDownload.schedules.dataSource', 'dataDownload.schedules.status', undefined]);
        });
    })

    describe('grid', function() {
        it('should call correct schedules view', function() {
            fixture.httpBackend.whenGET('api/ptoaccess/schedulesview')
                .respond({ schedules: fixture.viewData.schedules });

            var c = fixture.controller();
            c.$onInit();
            c.gridOptions.read();

            fixture.httpBackend.expectGET('api/ptoaccess/schedulesview');
            fixture.httpBackend.flush();

            expect(c.schedules.length).toEqual(fixture.viewData.schedules.length);
        });
    });

    describe('delete', function() {
        it('should make a delete request when user deletes a schedule.', function() {
            var c = fixture.controller();
            c.$onInit();
            var schedule = _.first(fixture.viewData.schedules);

            fixture.httpBackend.whenDELETE('api/ptoaccess/Schedules/' + schedule.id)
                .respond({ result: { result: 'success' } });

            c.onDelete(schedule);

            fixture.httpBackend.expectDELETE('api/ptoaccess/Schedules/' + schedule.id);
            fixture.httpBackend.flush();
        });
    })

    describe('run now', function() {
        it('should make a run now request when the user runs an ad hoc schedule.', function() {

            var c = fixture.controller();
            c.$onInit();
            var schedule = _.first(fixture.viewData.schedules);

            fixture.httpBackend.whenPOST('api/ptoaccess/Schedules/RunNow/' + schedule.id)
                .respond(function() {
                    return { result: { result: 'success' } };
                });

            c.onRunNow(schedule);

            fixture.httpBackend.expectPOST('api/ptoaccess/Schedules/RunNow/' + schedule.id);
            fixture.httpBackend.flush();
        });
    })
});