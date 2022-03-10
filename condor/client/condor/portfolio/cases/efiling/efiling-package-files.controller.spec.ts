'use strict';
namespace inprotech.portfolio.cases {
    describe('case view e-filing package files controller', () => {
        let controller: (viewData ?: any) => CaseViewEfilingPackageFilesController;
        let service: CaseViewEfilingServiceMock;
        let kendoGridBuilder: any;
        let eFilingPreview: IEfilingPreview;
        let promiseMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector([
                    'inprotech.mocks',
                    'inprotech.mocks.core'
                ]);

                service = $injector.get < ICaseviewEfilingService > (
                    'CaseViewEfilingServiceMock'
                );
                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                eFilingPreview = $injector.get<IEfilingPreview>('EFilingPreviewMock');
                promiseMock = $injector.get<any>('promiseMock');
            });

            inject(($rootScope) => {
                let scope = $rootScope.$new();
                controller = (viewData ?: any) => {
                    let c = new CaseViewEfilingPackageFilesController(
                        scope,
                        eFilingPreview,
                        kendoGridBuilder,
                        service
                    );
                    angular.extend(c, viewData);
                    return c;
                };
            });
        });

        describe('initialize', () => {
            it('should initialise grid options', () => {
                let c = controller();
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(c.gridOptions.pageable).toBe(false);
                expect(c.gridOptions.sortable).toEqual({
                    allowUnsort: true
                });
		expect(c.gridOptions.reorderable).toBe(false);
            });
        });

        describe('fetching data', () => {
            it('should call the service with correct parameters', () => {
                let c = controller({
                    caseKey: 123,
                    exchangeId: 456,
                    packageSequence: 789
                });
                c.$onInit();
                c.gridOptions.read();
                expect(service.getPackageFiles).toHaveBeenCalledWith(123, 456, 789);
            });
        });

        describe('clicking on a file', () => {
            let c: CaseViewEfilingPackageFilesController;
            beforeEach(() => {
                c = controller({
                    caseKey: 123,
                    exchangeId: 456,
                    packageSequence: 789
                });
                c.$onInit();
                c.gridOptions.read();
                service.getEfilingFileData = promiseMock.createSpy();
            });
            it('should create the url and open it', () => {
                c.clickFile(123, 789, 1, 456);
                expect(service.getEfilingFileData).toHaveBeenCalledWith(123, 789, 1, 456);
                expect(eFilingPreview.preview).toHaveBeenCalled();
            });
        });
    });
}