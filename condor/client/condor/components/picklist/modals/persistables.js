(function () {
    'use strict';

    angular.module('inprotech.components.picklist')
        .service('persistables', ['apiResolverService', 'picklistMaintenanceService', 'templateResolver', 'states',
            function (apiResolverService, picklistMaintenanceService, templateResolver, states) {

                var from = function (api, state, original, keyName, preventCopyColumns, additionalIdentifiers) {
                    var e = {};

                    switch (state) {
                        case states.duplicating:
                            preventCopyColumns.push(keyName);

                            var duplicate = {};

                            for (var key in original) {
                                var value = original[key];

                                if (preventCopyColumns.indexOf(key) == -1) {
                                    duplicate[key] = angular.copy(value);
                                }
                            }

                            angular.extend(duplicate, additionalIdentifiers);
                            e = api.$build(duplicate);
                            break;
                        case states.adding:
                            e = api.$build(additionalIdentifiers);
                            break;
                        case states.updating:
                        case states.deleting:
                        case states.viewing:
                            e = api.$find(encodeURIComponent(original[keyName]), additionalIdentifiers);
                            break;
                    }

                    return e;
                };

                return {
                    prepare: function (name, state, original, keyName, preventCopyColumns, additionalIdentifiers, isRestmod) {
                        var picklistObject, picklistTemplate, entry;

                        if (isRestmod === true) {
                            picklistObject = apiResolverService.resolve(name);
                            picklistTemplate = templateResolver.resolve(name, state);
                            entry = from(picklistObject, state, original, keyName, preventCopyColumns, additionalIdentifiers);
                        }
                        else {
                            picklistObject = picklistMaintenanceService.resolve(name);
                            picklistTemplate = templateResolver.resolve(name, state);
                            entry = from(picklistObject, state, original, keyName, preventCopyColumns, additionalIdentifiers)
                        }

                        return {
                            state: state,
                            template: picklistTemplate,
                            entry: entry,
                            api: picklistObject  
                        };
                    },
                    resolve: function (name, isRestmod) {
                        if (isRestmod === true) {
                            return apiResolverService.resolve(name);
                        } else {
                            return picklistMaintenanceService.resolve(name);
                        }
                    }
                };
            }
        ]);

})();
