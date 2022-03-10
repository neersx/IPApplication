describe('inprotech.picklists.DataItemsPicklistController', () => {
  'use strict';

  let controller: (dependencies?: any) => DataItemsPicklistController,
    notificationService: any,
    modalService: any,
    scope: any,
    entityStates: any,
    uibModalInstance: any,
    hotkeys: any;

  beforeEach(() => {
    angular.mock.module('inprotech.configuration.general.dataitem');

    angular.mock.module(() => {
      let $injector: ng.auto.IInjectorService = angular.injector([
        'inprotech.mocks.components.notification',
        'inprotech.mocks'
      ]);

      notificationService = $injector.get('notificationServiceMock');
      uibModalInstance = $injector.get('ModalInstanceMock');
      modalService = $injector.get('modalServiceMock');
      hotkeys = $injector.get('hotkeysMock');
    });
  });

  beforeEach(inject((
    $rootScope: ng.IRootScopeService,
    states: any,
    $translate
  ) => {
    scope = <ng.IScope>$rootScope.$new();
    entityStates = states;

    controller = dependencies => {
      dependencies = _.extend({}, dependencies);
      return new DataItemsPicklistController(
        scope,
        hotkeys,
        modalService,
        notificationService,
        uibModalInstance,
        entityStates,
        $translate
      );
    };
  }));

  describe('init', () => {
    it('should initialize the sqlstatement flag to true', () => {
      scope = {
        vm: {
          maintenance: {
            $dirty: true,
            $valid: true
          },
          maintenanceState: 'adding',
          entry: {
            isSqlStatement: false
          }
        }
      };
      controller();
      expect(scope.vm.entry.isSqlStatement).toBe(true);
    });

    it('should initialize the sqlstatement flag to false', () => {
      scope = {
        vm: {
          maintenance: {
            $dirty: true,
            $valid: true
          },
          maintenanceState: 'updating',
          entry: {
            isSqlStatement: false
          }
        }
      };
      controller();
      expect(scope.vm.entry.isSqlStatement).toBe(false);
    });
  });

  describe('onBeforeSave', () => {
    it('should call notifiction confirmation', () => {
      let message =
        'dataItem.maintenance.editConfirmationMessage' +
        '<br/>' +
        'dataItem.maintenance.proceedConfirmation';

      scope = {
        vm: {
          maintenance: {
            name: {
              $dirty: true
            }
          },
          maintenanceState: 'updating',
          entry: {
            isSqlStatement: false,
            sql: {}
          }
        }
      };

      let callback = $scope => {
        return;
      };

      let ctrl = controller();
      ctrl.onBeforeSave(scope.vm.entry, callback);

      expect(notificationService.confirm).toHaveBeenCalledWith({
        message: message,
        cancel: 'Cancel',
        continue: 'Proceed'
      });
    });

    it('should call initialiseSqlFields method', () => {
      scope = {
        vm: {
          maintenance: {
            name: {
              $dirty: false
            }
          },
          maintenanceState: 'updating',
          entry: {
            isSqlStatement: false,
            sql: {}
          }
        }
      };

      let callback = $scope => {
        return;
      };

      let ctrl = controller();
      spyOn(ctrl, 'initialiseSqlFields');
      ctrl.onBeforeSave(scope.vm.entry, callback);
      expect(ctrl.initialiseSqlFields).toHaveBeenCalledWith(callback);
    });
  });

  describe('initialiseSqlFields', () => {
    it('should initialize the storeprocedure to null', () => {
      scope = {
        vm: {
          maintenanceState: 'adding',
          entry: {
            isSqlStatement: true,
            sql: {
              storedProcedure: 'testProc'
            }
          }
        }
      };
      let ctrl = controller();

      let callback = $scope => {
        return;
      };

      ctrl.initialiseSqlFields(callback);
      expect(scope.vm.entry.sql.storedProcedure).toBe(null);
    });

    it('should initialize the sql statement to null', () => {
      scope = {
        vm: {
          maintenanceState: 'adding',
          entry: {
            isSqlStatement: false,
            sql: {
              sqlStatement: 'select * from item'
            }
          }
        }
      };

      let ctrl = controller();

      let callback = $scope => {
        return;
      };

      ctrl.initialiseSqlFields(callback);
      expect(scope.vm.entry.sql.storedProcedure).toBe(null);
    });
  });

  describe('dismissAll', () => {
    it('should cancel', () => {
      scope = {
        vm: {
          maintenance: {
            $dirty: false
          }
        }
      };

      let ctrl = controller();

      spyOn(ctrl, 'cancel');

      ctrl.dismissAll();

      expect(ctrl.cancel).toHaveBeenCalled();
    });

    it('should prompt notification if there are any unsaved changes', () => {
      scope = {
        vm: {
          maintenance: {
            $dirty: true
          }
        }
      };

      let ctrl = controller();

      ctrl.dismissAll();

      expect(notificationService.discard).toHaveBeenCalled();
    });
  });

  describe('disable', () => {
    it('disable should return false', () => {
      scope = {
        vm: {
          maintenance: {
            $dirty: true,
            $valid: true
          }
        }
      };

      let ctrl = controller();

      expect(ctrl.disable()).toBe(false);
    });

    it('disable should return true', () => {
      scope = {
        vm: {
          maintenance: {
            $dirty: false,
            $valid: true
          }
        }
      };

      let ctrl = controller();

      expect(ctrl.disable()).toBe(true);
    });
  });

  describe('cancel', () => {
    it('should close modal instance', () => {
      scope = {
        vm: {
          maintenance: {
            $dirty: false,
            $valid: true
          }
        }
      };

      let ctrl = controller();
      ctrl.cancel();
      expect(uibModalInstance.close).toHaveBeenCalled();
    });
  });
});
