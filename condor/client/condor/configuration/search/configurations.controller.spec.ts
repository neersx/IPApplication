namespace inprotech.configuration.search {

    describe('inprotech.configuration.search.ConfigurationsController', () => {
        'use strict';

        let controller: (dependencies?: any) => ConfigurationsController, scope: IConfigurationsScope,
            kendoGridBuilder: any, configurationsService: IConfigurationsService, featureDetection: any,
            modalService: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.search');
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.search', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);

                configurationsService = $injector.get<IConfigurationsService>('ConfigurationsServiceMock');

                kendoGridBuilder = $injector.get('kendoGridBuilderMock');

                featureDetection = $injector.get('featureDetectionMock');

                modalService = $injector.get('modalServiceMock');
            });
        });

        beforeEach(inject(($q: ng.IQService, $rootScope: ng.IRootScopeService) => {
            scope = <IConfigurationsScope>$rootScope.$new();
            controller = function (dependencies?) {
                dependencies = angular.extend({
                    viewData: {
                        canUpdate: true
                    }
                }, dependencies);
                return new ConfigurationsController(scope, dependencies.viewData, configurationsService, kendoGridBuilder, featureDetection, modalService);
            };
        }));

        describe('initialise view', () => {
            let c: ConfigurationsController, viewData: any;
            beforeEach(() => {
                viewData = {
                    canUpdate: true
                };
                c = controller({
                    viewData: viewData
                });
            })

            it('should set canUpdate object ', () => {
                expect(c.canUpdate).toBe(viewData.canUpdate);
            });

            it('should call kendoGridBuilder buildOptions for grid formation', () => {
                expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            });

            it('should define scope object ', () => {
                expect(scope.service).toBeDefined();
            });

            it('should define functions', () => {
                expect(c.resetOptions).toBeDefined();
                expect(c.search).toBeDefined();
                expect(c.gridOptions).toBeDefined();
                expect(c.showIeRequired).toBeDefined();
                expect(c.checkLegacyLinkCompatibility).toBeDefined();
                expect(c.buildLink).toBeDefined();
            });
        });

        describe('searching', () => {
            let c: ConfigurationsController;
            beforeEach(() => {
                c = controller();
            });

            it('should invoke service to perform search', () => {
                c.search();

                expect(c.gridOptions.search).toHaveBeenCalled();
            });

            it('should clear search results when Clear button is clicked', () => {
                c.resetOptions();

                expect(c.gridOptions.clear).toHaveBeenCalled();
            });
        });
    });
}
