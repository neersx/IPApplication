describe('inprotech.configuration.general.dataitem.DataItemMaintenanceController', () => {
    'use strict';

    let controller: (dependencies?: any) => DataItemMaintenanceController,
        notificationService: any, dataItemService: any, scope: any, entityStates: any;

    beforeEach(() => {
        angular.mock.module('inprotech.configuration.general.dataitem');

        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService =
                angular.injector(['inprotech.mocks.components.notification', 'inprotech.mocks']);

            notificationService = $injector.get('notificationServiceMock');
            dataItemService = $injector.get('DataItemServiceMock');
        });
    });

    beforeEach(inject(($rootScope: ng.IRootScopeService, states: any) => {
        scope = <ng.IScope>$rootScope.$new();
        entityStates = states;

        controller = (dependencies) => {
            dependencies = _.extend(
                {
                }, dependencies);
            return new DataItemMaintenanceController(scope, entityStates,
                dataItemService, notificationService);
        };
    }));

    describe('resetSql', () => {
        it('should reset sql to null', () => {
            scope = {
                model: {
                    state: 'adding'
                },
                maintenance: {},
                errors: {},
                saveCall: true
            };

            let ctrl = controller();
            spyOn(ctrl, 'resetSqlError');

            ctrl.resetSql();
            expect(scope.model.sql).toEqual(null);
            expect(ctrl.resetSqlError).toHaveBeenCalled();
        });
    });

    describe('afterValidate', () => {
        it('should call notificationservice with success', () => {
            let ctrl = controller();
            let response = {
                data: null
            };

            ctrl.afterValidate(response);

            expect(notificationService.success).toHaveBeenCalled();
        });
        it('should call alert when there is error', () => {
            let ctrl = controller();
            let response = {
                data: {
                    errors: [{
                        id: null,
                        field: 'invalidsql',
                        topic: 'error',
                        message: 'error'
                    }]
                }
            };

            ctrl.afterValidate(response);

            expect(notificationService.alert).toHaveBeenCalledWith({
                title: 'field.errors.invalidsql',
                message: ctrl.getError('invalidsql').topic,
                errors: _.where(response.data.errors, {
                    field: null
                })
            });
        });
    });

    describe('resetSqlError', () => {
        it('should call reset sql error with sqlstatement true', () => {
            scope = {
                model: {
                    state: 'adding',
                    isSqlStatement: true
                },
                maintenance: {},
                errors: [{
                    id: null,
                    field: 'invalidsql',
                    topic: 'error',
                    message: 'error'
                }],
                saveCall: true
            };
            let ctrl = controller();
            spyOn(ctrl, 'getError');
            spyOn(ctrl, 'removeError');
            ctrl.resetSqlError();
            expect(ctrl.getError).toHaveBeenCalledWith('statement');
            expect(ctrl.removeError).toHaveBeenCalledWith('statement');
        });
        it('should call reset sql error with sqlstatement false', () => {
            scope = {
                model: {
                    state: 'adding',
                    isSqlStatement: false
                },
                maintenance: {},
                errors: [{
                    id: null,
                    field: 'invalidsql',
                    topic: 'error',
                    message: 'error'
                }],
                saveCall: true
            };
            let ctrl = controller();
            spyOn(ctrl, 'getError');
            spyOn(ctrl, 'removeError');
            ctrl.resetSqlError();
            expect(ctrl.getError).toHaveBeenCalledWith('procedurename');
            expect(ctrl.removeError).toHaveBeenCalledWith('procedurename');
        });
    });
});