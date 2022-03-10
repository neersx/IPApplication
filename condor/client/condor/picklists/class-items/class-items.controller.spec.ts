describe('inprotech.picklists.classItemsController', () => {
  'use strict';

  let controller: (dependencies?: any) => ClassItemsController,
    scope: any,
    entityStates: any,
    http: any;

  beforeEach(() => {
    angular.mock.module('inprotech.picklists');

    angular.mock.module(() => {
      let $injector: ng.auto.IInjectorService = angular.injector([
        'inprotech.mocks'
      ]);

      http = $injector.get('httpMock');
    });
  });

  beforeEach(inject(($rootScope: ng.IRootScopeService, states: any) => {
    scope = <ng.IScope>$rootScope.$new();
    scope.vm = {
      initialViewData: {
        class: '01',
        countryCode: 'AU',
        propertyType: 'T'
      },
      maintenanceState: 'adding',
      entry: {}
    };
    entityStates = states;

    controller = dependencies => {
      dependencies = _.extend({}, dependencies);
      return new ClassItemsController(scope, entityStates, http);
    };
  }));

  describe('initviewdata', () => {
    it('should initialize the entry model with initial view data when adding', () => {
      scope.vm.initialViewData.subClass = 'A';

      controller();

      expect(scope.vm.entry.class).toBe('01');
      expect(scope.vm.entry.subClass).toBe('A');
      expect(scope.vm.entry.country).toBe('AU');
      expect(scope.vm.entry.propertyType).toBe('T');
    });

    it('should initialize the entry model with backend call for subclasses', () => {
      controller();

      expect(scope.vm.entry.class).toBe('01');
      expect(scope.vm.entry.country).toBe('AU');
      expect(scope.vm.entry.propertyType).toBe('T');
      expect(http.get).toHaveBeenCalledWith(
        'api/picklists/classitems/subclasses/AU/T/01'
      );
    });
  });
  describe('language field disabled', () => {
    it('language field is disabled when trying to update default class item', () => {
      scope.vm.maintenanceState = 'updating';
      scope.vm.entry.isDefaultItem = true;

      let c = controller();

      expect(c.languageDisabled()).toBeTruthy();
    });
    it('language field is enabled when trying to update specific language class item', () => {
      scope.vm.maintenanceState = 'updating';
      scope.vm.entry.isDefaultItem = false;

      let c = controller();

      expect(c.languageDisabled()).toBeFalsy();
    });
    it('language field is disabled when trying to view class item details in viewing state', () => {
      scope.vm.maintenanceState = 'viewing';

      let c = controller();

      expect(c.languageDisabled()).toBeTruthy();
    });
  });
  describe('item no field disabled', () => {
    it('item number field is enabled when either subclass or language is relevant', () => {
      scope.vm.maintenanceState = 'updating';
      scope.vm.entry = {
        subClass: null,
        language: {
          key: 'F',
          code: 'F',
          value: 'french'
        }
      };

      let c = controller();

      expect(c.isItemNoDisabled()).toBeFalsy();
    });
    it('item number field is disabled when both subclass and language are not entered by user', () => {
      scope.vm.maintenanceState = 'updating';
      scope.vm.entry = {
        subClass: null,
        language: null
      };

      let c = controller();

      expect(c.isItemNoDisabled()).toBeTruthy();
    });
    it('item number field is disabled when trying to view class item details in viewing state', () => {
      scope.vm.maintenanceState = 'viewing';
      scope.vm.entry = {
        subClass: 'A',
        language: {
          key: 'F',
          code: 'F',
          value: 'french'
        }
      };

      let c = controller();

      expect(c.isItemNoDisabled()).toBeTruthy();
    });
  });
  describe('on language changed', () => {
    it('on clearing language field , item number field should be reset to null', () => {
      scope.vm.entry = {
        subClass: null,
        language: null
      };
      scope.vm.maintenance = {
        itemno: {
          $setValidity: jasmine.createSpy()
        }
      };

      let c = controller();
      c.onLanguageChange();

      expect(scope.vm.entry.itemNo).toBe(null);
      expect(scope.vm.maintenance.itemno.$setValidity).toHaveBeenCalledWith(
        'required',
        true
      );
    });
  });
  describe('on subclass change', () => {
    it('on subclass field change, item number field should be reset to null', () => {
      scope.vm.maintenance = {
        itemno: {
          $setValidity: jasmine.createSpy()
        }
      };

      let c = controller();
      c.onSubClassChange();

      expect(scope.vm.entry.itemNo).toBe(null);
      expect(scope.vm.maintenance.itemno.$setValidity).toHaveBeenCalledWith(
        'required',
        true
      );
    });
  });
  describe('onbeforesave', () => {
    it('sets required field error if subclass is entered and item no field is left blank', () => {
      let c = controller();

      let entry = {
        subClass: 'A',
        itemNo: ''
      };
      let callback = jasmine.createSpy();
      scope.vm.maintenance = {
        itemno: {
          $setValidity: jasmine.createSpy()
        }
      };
      c.onBeforeSave(entry);
      expect(scope.vm.maintenance.itemno.$setValidity).toHaveBeenCalledWith(
        'required',
        false
      );
    });
    it('sets required field error if language is entered and item no field is left blank', () => {
      let c = controller();

      let entry = {
        itemNo: '',
        language: {
          key: 'F',
          code: 'F',
          value: 'french'
        }
      };

      scope.vm.maintenance = {
        itemno: {
          $setValidity: jasmine.createSpy()
        }
      };

      c.onBeforeSave(entry);

      expect(scope.vm.maintenance.itemno.$setValidity).toHaveBeenCalledWith(
        'required',
        false
      );
    });
    it('sets flag to continue save when validation is successfull and callback is executed', () => {
      let c = controller();

      let entry = {
        subClass: 'A',
        itemNo: 'I01'
      };
      scope.vm.saveWithoutValidate = jasmine.createSpy();
      scope.vm.maintenance = {
        itemno: {
          $setValidity: jasmine.createSpy()
        }
      };

      c.onBeforeSave(entry);

      expect(scope.vm.saveWithoutValidate).toHaveBeenCalled();
    });
  });
});
