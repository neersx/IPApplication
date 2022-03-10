'use strict';

namespace Inprotech.Integration.PtoAccess {

    describe('usptoPrivatePairSponsorshipsController', function () {
        let controller, notificationService, modalService, sponsorshipService, kendoGridBuilder, q, rootScope, dateService;

        beforeEach(function () {
            angular.mock.module('Inprotech.Integration.PtoAccess')
        });

        beforeEach(
            angular.mock.module(function () {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
                modalService = $injector.get('modalServiceMock');
                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                notificationService = $injector.get('notificationServiceMock');
                sponsorshipService = $injector.get<ISponsorshipService>('sponsorshipServiceMock');
                dateService = $injector.get('dateServiceMock');
            }));

        beforeEach(
            inject(function ($rootScope: ng.IRootScopeService, $q: ng.IQService) {
                let scope = $rootScope.$new();
                controller = () => {
                    return new UsptoPrivatePairSponsorshipsController(
                        scope, modalService, kendoGridBuilder, notificationService, sponsorshipService, dateService);
                };
                q = $q;
                rootScope = $rootScope;
            })
        );

        let c: UsptoPrivatePairSponsorshipsController;
        describe('tests', () => {
            let setServiceData;
            beforeEach(() => {
                c = controller();
                rootScope.$apply();
                setServiceData = (data) => {
                    sponsorshipService.get.returnValue = data || {
                        sponsorships: [{
                            id: 1,
                            name: 'cert1',
                            customerNumbers: '111111, 33333'
                        }, {
                            id: 2,
                            name: 'cert2',
                            customerNumbers: '55555, 77777'
                        }],
                        canScheduleDataDownload: true,
                        clientId: 'client001',
                        missingBackgroundProcessLoginId: true
                    };
                };
            });
            it('should initialize', function () {
                expect(c.canScheduleDataDownload).toBe(false);
                expect(c.missingBackgroundProcessLoginId).toBe(false);
                expect(c.onAddOrUpdate).toBeDefined();
                expect(c.onDelete).toBeDefined();
                expect(c.gridOptions).toBeDefined();
            });

            it('should open modal with correct customer numbers', function () {
                setServiceData();
                c.gridOptions.read();

                c.onAddOrUpdate({});

                expect(modalService.openModal).toHaveBeenCalledWith({
                    id: 'NewUsptoSponsorship',
                    controllerAs: 'vm',
                    data: {
                        item: Object({}),
                        customerNumbers: '111111, 33333, 55555, 77777',
                        clientId: 'client001'
                    }
                });
            });

            it('should open modal on Add click', function () {
                c.onAddOrUpdate({});
                expect(modalService.openModal).toHaveBeenCalledWith({
                    id: 'NewUsptoSponsorship',
                    controllerAs: 'vm',
                    data: {
                        item: Object({}),
                        customerNumbers: '',
                        clientId: undefined
                    }
                });
            });

            it('should delete sponsorship', function () {
                (notificationService.confirmDelete as jasmine.Spy).and.returnValue(q.when({}));
                c.onDelete(1);
                rootScope.$apply();

                expect(notificationService.confirmDelete).toHaveBeenCalledWith({
                    message: 'modal.confirmDelete.message'
                });
                expect(sponsorshipService.delete).toHaveBeenCalledWith(1);
            });

            it('should search sponsorship', function () {
                setServiceData();
                let response = c.gridOptions.read();

                expect(sponsorshipService.get).toHaveBeenCalled();
                expect(response.length).toEqual(2);
                expect(c.canScheduleDataDownload).toBeTruthy();
                expect(c.missingBackgroundProcessLoginId).toBeTruthy();
                expect(c.gridOptions.columns.length).toEqual(5);
            });

            it('should populate customer numbers', function () {
                setServiceData();
                let response = c.gridOptions.read();

                expect(sponsorshipService.get).toHaveBeenCalled();
                expect(response.length).toEqual(2);
                expect(c.customerNumbers).toEqual('111111, 33333, 55555, 77777');
            });

            describe('global account change', function () {
                it('should show the edit button correctly', function () {
                    expect(c.hasSponsorship).toBe(false);

                    setServiceData();
                    c.gridOptions.read();

                    expect(c.hasSponsorship).toBe(true);
                });
                it('should not show button if either of client id or sponsorships not present', function () {
                    setServiceData({
                        sponsorships: [],
                        clientId: 'client001'
                    });
                    c.gridOptions.read();
                    expect(c.hasSponsorship).toBeFalsy();

                    setServiceData({
                        sponsorships: [{
                            id: 1,
                            name: 'cert1',
                            customerNumbers: '111111, 33333'
                        }, {
                            id: 2,
                            name: 'cert2',
                            customerNumbers: '55555, 77777'
                        }]
                    });
                    c.gridOptions.read();
                    expect(c.hasSponsorship).toBeFalsy();
                });

                it('should open modal on edit click', function () {
                    c.onUpdateAccountDetails();
                    expect(modalService.openModal).toHaveBeenCalledWith({
                        id: 'updateUsptoAccountDetails',
                        controllerAs: 'vm',
                        data: {
                            clientId: undefined
                        }
                    });
                });
            });
        });
    });
}