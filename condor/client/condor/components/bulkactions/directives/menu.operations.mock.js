angular.module('inprotech.mocks').factory('BulkMenuOperationsMock', function () {
    'use strict';

    var mock = function (context) {
        this.context = context;
    };

    mock.prototype = {
        selectAll: angular.noop,
        clearAll: angular.noop,
        selectionChange: angular.noop,
        anySelected: angular.noop,
        selectedRecords: angular.noop,
        selectedRecord: angular.noop,
        selectPage: angular.noop,
        initialiseMenuForPaging: angular.noop,
        singleSelectionChange: angular.noop,
        clearSelectedItemsArray: angular.noop
    };

    test.spyOnAll(mock.prototype);

    return mock;
});
