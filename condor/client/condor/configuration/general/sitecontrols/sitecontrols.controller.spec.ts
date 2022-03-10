namespace inprotech.configuration.general.sitecontrols {

    describe('inprotech.configuration.general.sitecontrols.SiteControlsController', () => {
        'use strict';

        let controller: (dependencies?: any) => SiteControlsController , scope: ISiteControlsScope,
        notificationService: any, kendoGridBuilder: any, siteControlService: ISiteControlService;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.sitecontrols');
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks.configuration.general.sitecontrols', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);

                siteControlService = $injector.get<ISiteControlService>('SiteControlServiceMock');

                kendoGridBuilder = $injector.get('kendoGridBuilderMock');

                notificationService = $injector.get('notificationServiceMock');
            });
        });

        beforeEach(inject(($q: ng.IQService, $rootScope: ng.IRootScopeService) => {
            scope = <ISiteControlsScope>$rootScope.$new();
            controller = function(dependencies?) {
                dependencies = angular.extend({
                    viewData: {
                        components: [],
                        releases: [],
                        tags: []
                    }
                }, dependencies);
                return new SiteControlsController(scope, $q, dependencies.viewData, siteControlService, kendoGridBuilder, notificationService);
            };
        }));

        describe('initialise view', () => {
            let c: SiteControlsController, viewData: any;
            beforeEach(() => {
                viewData = {
                    releases: 'releases',
                    canUpdateSiteControls: true
                };
                c = controller({
                    viewData: viewData
                });
            })
            it('should set canUpdateSiteControls object ', () => {
                expect(c.canUpdateSiteControls).toBe(viewData.canUpdateSiteControls);
            });
            it('should set searchOptions object ', () => {
                expect(c.searchOptions.releases).toBe(viewData.releases);
            });
            it('should set searcCriteria object ', () => {
                expect(c.searchCriteria.isByName).toBe(true);
                expect(c.searchCriteria.isByDescription).toBe(false);
                expect(c.searchCriteria.isByValue).toBe(false);
            });
            it('should call kendoGridBuilder buildOptions for grid formation', () => {
                expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            });
            it('should define scope object ', () => {
                expect(scope.service).toBeDefined();
                expect(scope.showCurrentValue).toBeDefined();
            });
            it('should define functions', () => {
                expect(c.resetOptions).toBeDefined();
                expect(c.search).toBeDefined();
                expect(c.onSearchByChange).toBeDefined();
                expect(c.save).toBeDefined();
                expect(c.discard).toBeDefined();
                expect(c.gridOptions).toBeDefined();
            });
        });

        describe('searching', () => {
            let c: SiteControlsController;
            beforeEach(() => {
                c = controller();
            });
            it('last search by option cannot be deselected', () => {
                c.onSearchByChange('isByName');
                expect(c.searchCriteria.isByName).toBe(true);
            });
            it('should invoke service to perform search', () => {
                scope.service.isDirty.returnValue = false;
                c.search();

                expect(c.gridOptions.search).toHaveBeenCalled();
                expect(scope.service.reset).toHaveBeenCalled();
            });

            it('should prompt notification if there are any unsaved changes', () => {
                scope.service.isDirty.returnValue = true;
                c.search();

                expect(notificationService.unsavedchanges).toHaveBeenCalled();
            });

            it('should proceed searching if discard changes', () => {
                scope.service.isDirty.returnValue = true;
                notificationService.unsavedchanges.discard = true;
                c.search();

                expect(scope.service.discard).toHaveBeenCalled();
                expect(c.gridOptions.search).toHaveBeenCalled();
                expect(scope.service.reset).toHaveBeenCalled();
            });

            it('should save changes when clicking on Save button', () => {
                scope.service.isDirty.returnValue = true;
                notificationService.unsavedchanges.save = true;
                c.search();

                expect(scope.service.save).toHaveBeenCalled();
            });

            it('should clear search results when Clear button is clicked', () => {
                scope.service.isDirty.returnValue = false;
                c.resetOptions();

                expect(c.gridOptions.clear).toHaveBeenCalled();
            });

            it('should prompt notification if cleared and there are any unsaved changes', () => {
                scope.service.isDirty.returnValue = true;
                c.resetOptions();

                expect(notificationService.unsavedchanges).toHaveBeenCalled();
            });
        });

        describe('saving changes', () => {
            let c: SiteControlsController;
            beforeEach(() => {
                c = controller();
            });
            it('should show success notification after saved', () => {
                scope.service.hasError.returnValue = false;

                c.save();

                expect(scope.service.save).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
            });

            it('should prompt warning if there are any validation errors', () => {
                scope.service.hasError.returnValue = true;
                c.save();

                expect(notificationService.alert).toHaveBeenCalled();
                expect(scope.service.getInvalidSiteControls).toHaveBeenCalled();
            });
        });

        describe('discarding changes', () => {
            it('should discard if confirmed', () => {
                let c: SiteControlsController = controller();
                c.discard();

                expect(scope.service.discard).toHaveBeenCalled();
            });
        });
    });
}
