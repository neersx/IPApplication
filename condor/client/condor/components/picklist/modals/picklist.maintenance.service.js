angular.module('inprotech.components.picklist').factory('picklistMaintenanceService',
    function ($http) {
        'use strict';

        var commonFunctions = {
            session: {},
            on: function (key, callback) {
                this[key] = callback;
                return this;
            },
            off: function (key) {
                delete this[key];
                return this;
            },
            finally: function (callback) {
                this['finally'] = callback;
                return null; // empty hook which will be removed after the full migration
            },
            duplicate: function (exceptColumns) {// duplicate only data from the object
                var result = {};
                for (var key in this) {
                    if (this.hasOwnProperty(key)) {
                        var meta = !angular.isFunction(this[key]) && (key !== 'session' );
                        var notExcluded = exceptColumns && exceptColumns.indexOf(key) === -1 || !exceptColumns;
                        if (meta && notExcluded) {
                            result[key] = angular.copy(this[key]);
                        }
                    }
                }
                return result;
            },
            destroy: function () {
                var instance = this;     
                if (!angular.isFunction(instance['after-destroy'])) {
                    instance['after-destroy'] = function (data) { return commonFunctions.$extend(data, instance.session); }
                }

                $http.delete(instance.session.apiUrl + '/' + this['key'], { params: this.$params }) // assuming obj will always deleted by key value
                    .then(function (response) {
                        instance['after-destroy'](response);
                        return response;
                    })
            },
            save: function () {      
                var instance = this;                
                var requestData = this.$duplicate();
                if (!angular.isFunction(instance['after-save'])) {
                    instance['after-save'] = function (response) { return commonFunctions.$extend(response, instance.session); }
                }
               
                if (requestData.key == null) {
                    delete requestData.key;
                    $http.post(instance.session.apiUrl, requestData)
                        .then(function (response) {
                            return instance['after-save'](response);// nextAction(response);
                        })
                } else {
                    $http.put(instance.session.apiUrl + '/' + requestData.key, requestData)
                        .then(function (response) {
                            return instance['after-save'](response);
                        })
                }

            },
            withParams: function (params) {
                return angular.extend(this, { $params: params });
            },
            $extend: function (response, session) {
                return angular.extend(response, {
                    session: session,
                    $on: this.on,
                    $off: this.off,
                    $finally: this.finally,
                    $duplicate: this.duplicate,
                    $destroy: this.destroy,
                    $save: this.save,
                    withParams: this.withParams
                });
            }
        }
        return {
            resolve: function (key) {
                return {
                    session: { apiUrl: 'api/picklists/' + key },
                    init: function (initPage, skipMetaData, apiUrl) {
                        var sessionObj = this.session;
                        if (skipMetaData === true) {
                            var initObj = {
                                columns: [],
                                maintainability: {},
                                maintainabilityActions: null,
                                duplicateFromServer: false
                            };
                            if (apiUrl) {
                                this.session.apiUrl = apiUrl;
                            }
                            initPage(initObj);
                        } else {
                            sessionObj.apiUrl = 'api/picklists/' + key;  //some encoding later
                            $http.get(sessionObj.apiUrl + '/meta').then(function (response) {
                                initPage(angular.copy(response.data));
                            });
                        }
                    },
                    $search: function (query) {
                        var sessionObj = this.session;
                        return {
                            $Params: query,
                            $asPromise: function () {
                                return $http.get(sessionObj.apiUrl, {
                                    params: this.$Params
                                }).then(function (response) {
                                    var rawData = angular.copy(response.data);
                                    return angular.extend(commonFunctions.$extend(response.data['data'], sessionObj), {
                                        $metadata: rawData,
                                        $encode: function () {
                                            return this;
                                        },
                                        $then: function (callback) {
                                            callback(this.$metadata);
                                        }
                                    });
                                });
                            }
                        };
                    },
                    $build: function (fromObj) {
                        var sessionObj = this.session;
                        var result = {};
                        if (angular.isObject(fromObj)) {
                            result = fromObj;
                        }

                        return {
                            $metadata: result,
                            $then: function (callback) {
                                callback(commonFunctions.$extend(this.$metadata, sessionObj));
                            }
                        };
                    },
                    $find: function (key, additionalIdentifiers) {
                        var sessionObj = this.session;
                        return {
                            $then: function (callback) {
                                return $http.get(sessionObj.apiUrl + '/' + key, { params: additionalIdentifiers })
                                    .then(function (response) {
                                        if(response.data.data && !response.data.data.key) {
                                                response.data.data.key = key;                                            
                                        }
                                        callback(commonFunctions.$extend(response.data.data, sessionObj));
                                    });
                            }
                        };
                    }

                }
            }
        }
    });
