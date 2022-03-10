namespace inprotech.components.picklist {
    describe('inprotech.components.picklist.name', () => {
        'use strict';

        interface IPicklistNamesPaneServiceMock extends IPicklistNamesPaneService {
            setReturnValue(val): any;
        }

        let controller: (viewData?: any) => PicklistNamesPaneController, scope: ng.IScope,
            picklistNamesPaneService: IPicklistNamesPaneServiceMock,
            dateService: any;

        beforeEach(() => {
            angular.mock.module('inprotech.components.picklist');
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(
                    ['inprotech.mocks']);
                dateService = $injector.get('dateServiceMock');
                picklistNamesPaneService = $injector.get<IPicklistNamesPaneServiceMock>('PicklistNamesPaneServiceMock');
            });
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService) => {
            scope = <ng.IScope>$rootScope.$new();
            controller = function (viewData?) {
                viewData = angular.extend({
                    nameId: 123,
                }, viewData);

                let c = new PicklistNamesPaneController(scope, picklistNamesPaneService, dateService);
                c.nameId = viewData.nameId;
                return c;
            };
        }));

        describe('initialise view', () => {
            let c: PicklistNamesPaneController;
            beforeEach(() => {
                c = controller();
            })

            it('should initialise variables', () => {
                expect(c.nameId).toBe(123);
            });
        });

        describe('load data', () => {
            it('calls the detail service when nameId is set', () => {
                let c: PicklistNamesPaneController = controller();

                c.nameId = null;
                c.loadData();
                expect(picklistNamesPaneService.getName).not.toHaveBeenCalled();

                c.nameId = 10054;
                picklistNamesPaneService.setReturnValue({
                    nameDetailData: {}
                });
                c.loadData();
                expect(picklistNamesPaneService.getName).toHaveBeenCalledWith(10054);
              });

            it('loads the data into the controller', () => {
                let c: PicklistNamesPaneController = controller();

                c.nameId = 123;
                let nameDetails = {
                    nameDetailData: { 'Key': '123', 'Code': 'ABC' }
                };
                picklistNamesPaneService.setReturnValue(nameDetails);
                c.loadData();
                expect(c.nameDetailData).toBe(nameDetails);
            });
        });
    });
}