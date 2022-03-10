describe('inprotech.configuration.general.validcombination.ValidDateOfLawMaintenanceController', () => {
    'use strict';

    let controller: (dependencies?: any) => ValidDateOfLawMaintenanceController, scope: any,
        dateHelper: any, kendoGridBuilder: any, entityStates: any, jurisdictionMaintenanceSvc: any,
        inlineEdit: any;

    beforeEach(() => {
        angular.mock.module('inprotech.configuration.general.validcombination');
        angular.mock.module(() => {
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            jurisdictionMaintenanceSvc = $injector.get('JurisdictionMaintenanceServiceMock');
            inlineEdit = {
                defineModel: jasmine.createSpy().and.returnValue([{
                    name: 'retrospectiveAction',
                    equals: (objA, objB) => {
                        return objA.key === objB.key;
                    }
                }, {
                    name: 'defaultEventForLaw',
                    equals: (objA, objB) => {
                        return objA.key === objB.key;
                    }
                }, {
                    name: 'defaultRetrospectiveEvent',
                    equals: (objA, objB) => {
                        return objA.key === objB.key;
                    }
                }, 'key'
                ]),
                hasError: jasmine.createSpy(),
                canSave: jasmine.createSpy()
            };
        });
    });

    beforeEach(inject(($rootScope: ng.IRootScopeService, states: any) => {
        scope = <ng.IScope>$rootScope.$new();
        entityStates = states;
        scope = {
            model: {
                affectedActions: [{
                    date: '1800-01-01T00:00:00',
                    defaultEventForLaw: {
                        key: 1,
                        value: 'value 1'
                    },
                    defaultRetrospectiveEvent: {
                        key: 1,
                        value: 'value 1'
                    },
                    jurisdiction: {
                        key: 'AU',
                        code: 'AU',
                        value: 'Australia'
                    },
                    key: 101,
                    propertyType: {
                        code: 'P',
                        key: 11,
                        value: 'Patents'
                    },
                    value: '1800-Jan-01',
                    retrospectiveAction: {
                        key: 1,
                        value: 'value 1'
                    }
                }]
            },
            vm: {
                maintenance: {
                    name: {
                        $dirty: true
                    }
                },
                maintenanceState: 'updating',
                entry: {
                }
            },
            $parent: {
                vm: {}
            }
        };
        controller = (dependencies) => {
            dependencies = _.extend(
                {
                    $scope: scope
                }, dependencies);
            return new ValidDateOfLawMaintenanceController(scope, kendoGridBuilder, dateHelper, entityStates, jurisdictionMaintenanceSvc, inlineEdit);
        };
    }));

    describe('on initialize', () => {
        it('grid should be defined', () => {
            let callback = ($scope) => {
                return;
            }

            scope.vm.saveWithoutValidate = () => {
                return;
            };

            let c = controller();
            spyOn(c, 'getDelta');
            c.onBeforeSave(scope.vm.entry, callback);
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(scope.affectedActions.gridOptions).toBeDefined();
            expect(_.pluck(scope.affectedActions.gridOptions.columns, 'title')).toEqual(['picklist.dateoflaw.actions', 'picklist.dateoflaw.determiningEvent', 'picklist.dateoflaw.retrospectiveEvent']);
        });

        it('jurisdiction and property type should be populated from search criteria', () => {
            scope.state = entityStates.adding;
            scope.model.validCombinationKeys = {
                jurisdictionModel: {
                    key: 1,
                    code: 'AU',
                    value: 'Australia'
                },
                propertyTypeModel: {
                    key: 1,
                    code: 'P',
                    value: 'Patent'
                }
            };

            controller();
            expect(scope.model.defaultDateOfLaw.jurisdiction).toEqual(scope.model.validCombinationKeys.jurisdictionModel);
            expect(scope.model.defaultDateOfLaw.propertyType).toEqual(scope.model.validCombinationKeys.propertyTypeModel);
        });
    });

    describe('onSelectionChanged', () => {
        it('check duplication method should be called', () => {
            let c = controller();
            let item = {
                key: 1
            };
            spyOn(c, 'checkDuplicateError');
            c.onSelectionChange(item);
            expect(c.checkDuplicateError).toHaveBeenCalled();
        });
    });
    it('date of law check duplicate row', () => {
        scope.model.defaultDateOfLaw = {
            defaultEventForLaw: '1',
            defaultRetrospectiveEvent: '2'
        };
        let c = controller();
        jurisdictionMaintenanceSvc.isDuplicated = _.constant(false);
        let obj = {
            error: jasmine.createSpy(),
            key: 1
        };
        c.createObj = jasmine.createSpy().and.returnValue(inlineEdit)

        c.onSelectionChange(obj);

        expect(obj.error).toHaveBeenCalledWith('duplicate', false);
    });

    it('if grid is empty should return undefined', function () {
        let c = controller();
        spyOn(c, 'hasError');
        expect(c.hasError()).toBe(undefined);
    });
});