angular.module('Inprotech.Infrastructure')
    .service('fileReader', ['$q',
        function ($q) {
            'use strict';

            return {
                readAsText: function (file, encoding){
                    var fileReader = new FileReader();
                    var q = $q.defer();
                    fileReader.onload = function(){
                        q.resolve(fileReader.result);
                    };
                    fileReader.onerror = function(){
                        q.reject(fileReader.error);
                    };
                    fileReader.readAsText(file, encoding);
                    return q.promise;
                }
            };
        }]);
