'use strict';

namespace inprotech.portfolio.cases {
  describe('case view classes controller', () => {
    let controller,
      service: ICaseviewClassesService,
      store,
      kendoGridBuilder,
      localSettings,
      dateService,
      $timeout;
    beforeEach(() => {
      angular.mock.module('inprotech.portfolio.cases');
    });

    beforeEach(() => {
      angular.mock.module(() => {
        let $injector: ng.auto.IInjectorService = angular.injector([
          'inprotech.mocks',
          'inprotech.mocks.portfolio.cases'
        ]);
        service = $injector.get<ICaseviewClassesService>(
          'caseviewClassesServiceMock'
        );
        kendoGridBuilder = $injector.get('kendoGridBuilderMock');
        store = $injector.get('storeMock');
        dateService = $injector.get('dateServiceMock');
        localSettings = new inprotech.core.LocalSettings(store);
      });

      inject($rootScope => {
        let scope = $rootScope.$new();
        controller = (viewData?: any, topic?: any) => {
          let c = new CaseviewClassesController(
            scope,
            kendoGridBuilder,
            localSettings,
            service,
            dateService,
            $timeout
          );
          c.viewData = viewData || {
            caseKey: 1,
            allowSubClass: true,
            usesDefaultCountryForClasses: true
          };
          c.topic = topic;
          return c;
        };
      });
    });

    describe('initialize', () => {
      let viewData = {
        caseKey: 1
      };
      let topic = {};

      it('should call the service on initialization', () => {
        spyOn(service, 'getClassesSummary').and.returnValue({
          then: cb => {
            return cb({
              localClasses: '01'
            });
          }
        });

        let c = controller(viewData, topic);
        c.$onInit();
        expect(c.service.getClassesSummary).toHaveBeenCalledWith(c.viewData.caseKey);
      });
    });

    describe('initialize case classes grid', () => {
      let viewData = {
        caseKey: 1,
        allowSubClassWithoutItem: false
      };
      let topic = {};

      it('should initialise grid options with disable subclass', () => {
        let c = controller(viewData, topic);
        c.isExternal = false;
        c.$onInit();
        expect(c.gridOptions).toBeDefined();
        expect(store.local.get).toHaveBeenCalled();
        expect(c.gridOptions.columns.length).toBe(5);
        expect(c.gridOptions.columns[0].field).toBe('class');
        expect(c.gridOptions.columns[1].field).toBe('internationalEquivalent');
        expect(c.gridOptions.columns[2].field).toBe('gsText');
        expect(c.gridOptions.columns[3].field).toBe('dateFirstUse');
        expect(c.gridOptions.columns[4].field).toBe('dateFirstUseInCommerce');
      });
    });

    describe('initialize case classes grid for Enable Subclass', () => {
      let viewData = {
        caseKey: 1,
        allowSubClassWithoutItem: true
      };
      let topic = {};

      it('should initialise grid options with enable subclass', () => {
        let c = controller(viewData, topic);
        c.isExternal = false;
        c.$onInit();
        expect(c.gridOptions).toBeDefined();
        expect(store.local.get).toHaveBeenCalled();
        expect(c.gridOptions.columns.length).toBe(6);
        expect(c.gridOptions.columns[0].field).toBe('class');
        expect(c.gridOptions.columns[1].field).toBe('subClass');
        expect(c.gridOptions.columns[2].field).toBe('internationalEquivalent');
        expect(c.gridOptions.columns[3].field).toBe('gsText');
        expect(c.gridOptions.columns[4].field).toBe('dateFirstUse');
        expect(c.gridOptions.columns[5].field).toBe('dateFirstUseInCommerce');
      });
    });

    describe('initialize case classes grid for Default country disabled', () => {
      let viewData = {
        caseKey: 1,
        usesDefaultCountryForClasses: true
      };
      let topic = {};

      it('should dissapear international colum in a grid', () => {
        let c = controller(viewData, topic);
        c.isExternal = false;
        c.$onInit();
        expect(c.gridOptions).toBeDefined();
        expect(store.local.get).toHaveBeenCalled();
        expect(c.gridOptions.columns.length).toBe(4);
        expect(c.gridOptions.columns[0].field).toBe('class');
        expect(c.gridOptions.columns[1].field).toBe('gsText');
        expect(c.gridOptions.columns[2].field).toBe('dateFirstUse');
        expect(c.gridOptions.columns[3].field).toBe('dateFirstUseInCommerce');
      });
    });
  });
}
