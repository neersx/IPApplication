angular.module('inprotech.components.picklist').factory('picklistService', function(modalService, $translate) {
    return {
        openModal: function(scope, options) {
            var displayName = options.displayName || options.type.charAt(0).toUpperCase() + options.type.slice(1);
            displayName = $translate.instant(displayName);

            return modalService.open('Picklist.' + options.type + (options.canMaintain ? '_maintainable' : ''), scope, {
                options: {
                    entity: options.type,
                    apiUrl: options.apiUrl,
                    apiUriName: options.apiUriName,
                    searchValue: options.searchValue,
                    selectedItems: options.selectedItems,
                    multipick: options.multipick,
                    extendQuery: options.extendQuery,
                    canMaintain: options.canMaintain,
                    size: options.size,
                    fieldLabel: options.fieldLabel || displayName,
                    windowLabel: options.appendPicklistLabel ? (displayName + ' Pick List') : displayName,
                    externalScope: options.externalScope,
                    columns: options.columns,
                    columnMenu: options.columnMenu,
                    qualifiers: options.qualifiers,
                    initFunction: options.initFunction,
                    preSearch: options.preSearch,
                    editUriState: options.editUriState,
                    initialViewData: options.initialViewData,
                    canAddAnother: options.canAddAnother ? true : false,
                    previewable: options.previewable ? true : false,
                    dimmedColumnName: options.dimmedColumnName
                }
            }, options.templateUrl, 'vm');
        }
    };
});