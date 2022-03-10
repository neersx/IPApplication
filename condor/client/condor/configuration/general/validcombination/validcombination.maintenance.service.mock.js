angular.module('inprotech.mocks.configuration.validcombination').factory('ValidCombinationMaintenanceServiceMock', function() {
    'use strict';

    var r = {
        savedKeys: [],
        vc: {},
        modalOptions: {},
        handleAddFromMainController: jasmine.createSpy(),
        add: jasmine.createSpy(),
        addSavedKeys: jasmine.createSpy().and.callThrough(),
        clearSavedRows: jasmine.createSpy().and.callThrough(),
        persistSavedData: angular.noop,
        markInUseData: angular.noop,
        initialize: angular.noop,
        resetBulkMenu: jasmine.createSpy(),
        edit: jasmine.createSpy(),
        copy:jasmine.createSpy().and.callThrough(),
        resetSearchCriteria: jasmine.createSpy(),
        bulkMenuClearSelection: jasmine.createSpy()
    };
    return r;
});
