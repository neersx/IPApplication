angular.module('Inprotech.Infrastructure')
    .service('http', ['$http',
        function($http) {
            'use strict';
            var service = {

                get: function(url) {
                    var promise = $http.get(url);
                    promise.success = function(fn) {
                        return promise.then(function(response) {
                            response.data = response.data.result || response.data;
                            return fn(response.data, response.status, response.headers);
                        });
                    };
                    return promise;
                },
                post: function(url, body) {
                    var promise = $http.post(url, body);
                    promise.success = function(fn) {
                        return promise.then(function(response) {
                            if(response.data){
                                response.data = response.data.result || response.data;
                            }                            
                            return fn(response.data, response.status, response.headers);
                        });
                    };
                    return promise;
                }
            };
            return service;
        }
    ]);