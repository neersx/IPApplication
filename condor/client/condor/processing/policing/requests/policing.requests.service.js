angular.module('inprotech.processing.policing')
    .service('policingRequestService', function($http, utils) {
        var savedRequestIds = [];

        var preRequest = utils.cancellable();
        var validateCharacteristics = _.debounce(function(characteristics, callback) {
            preRequest.cancel();

            return $http.get('api/policing/requests/validateCharacteristics', {
                    params: {
                        characteristics: JSON.stringify(characteristics)
                    },
                    timeout: preRequest.promise
                })
                .then(function(response) {
                    return callback(response.data);
                });
        }, 100);

        return {
            savedRequestIds: savedRequestIds,
            uiPersistSavedRequests: function(requests) {
                _.each(requests, function(request) {
                    _.each(savedRequestIds, function(id) {
                        if (request.id === id) {
                            request.saved = true;
                        }
                    });
                });
                return requests;
            },
            get: function() {
                return $http.get('api/policing/requests/view').then(
                    function(response) {
                        return response.data;
                    }
                );
            },
            getRequest: function(requestId) {
                return $http.get('api/policing/requests/' + requestId).then(
                    function(response) {
                        return response.data;
                    }
                );
            },
            getRequests: function(queryParams) {
                return $http.get('api/policing/requests', {
                    params: {
                        params: JSON.stringify(queryParams)
                    }
                }).then(
                    function(response) {
                        return response.data;
                    }
                );
            },
            save: function(request) {
                if (request.requestId) {
                    return $http.put('api/policing/requests/' + request.requestId, request);
                }
                return $http.post('api/policing/requests', request);
            },
            delete: function(requestIds) {
                return $http.post('api/policing/requests/delete', requestIds);
            },
            runNow: function(requestId, runType) {
                return $http.post('api/policing/requests/RunNow/' + requestId + '?runType=' + runType);
            },
            markInUseRequests: function(resultSet, inUseIds) {
                _.each(resultSet, function(request) {
                    _.each(inUseIds, function(inUseId) {
                        if (request.id === inUseId) {
                            request.inUse = true;
                        }
                    });
                });
            },
            validateCharacteristics: function(characteristics, callback) {
                return validateCharacteristics(characteristics, callback);
            },
            getNextLettersDate: function(startDate) {
                return $http.get('api/policing/requests/lettersdate?startDate=' + encodeURI(startDate));
            }
        }
    });