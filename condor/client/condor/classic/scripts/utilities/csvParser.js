angular.module('Inprotech.Utilities')
    .service('csvParser', ['$q',
        function ($q) {
            'use strict';

            return {
                parse: function (csvContent){
                    var q = $q.defer();
                    Papa.parse(csvContent, {
                        header: true,
                        worker: true,
                        skipEmptyLines: true,
                        complete: function(results) {
                            if (results.errors.length > 0) {
                                q.reject(results.errors);
                                return;
                            }

                            q.resolve(results);
                        }
                    });
                    return q.promise;
                }
            };
        }]);
