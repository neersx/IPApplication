(function() {
    'use strict';
    angular.module('inprotech.components.picklist')
        .service('dataunwrapperservice', [function() {
            return {
                unwrap: function(data) {
                    var unwrappedData;
                    if (data.$metadata) {
                        var all = data.$metadata.columns;

                        var keyColumn = _.find(all, function(item) {
                            return item.key === true;
                        }).field;

                        var valueColumn = _.find(all, function(item) {
                            return item.description === true;
                        }).field;

                        var codeColumn = _.find(all, function(item) {
                            return item.code === true;
                        });

                        unwrappedData = [];
                        _.each(data, function(d) {
                            unwrappedData.push({
                                key: d[keyColumn],
                                code: codeColumn ? d[codeColumn.field] : null,
                                value: d[valueColumn],
                                model: d
                            });
                        });
                    }
                    return unwrappedData || data;
                }
            };
        }]);
})();
