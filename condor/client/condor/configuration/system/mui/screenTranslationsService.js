angular.module('inprotech.configuration.system.mui')
    .factory('ScreenTranslationsService', function($http, $q, ExtObjFactory) {
        'use strict';

        var extObjFactory = new ExtObjFactory().useDefaults().use('observableArray');

        function ScreenTranslationsService() {
            this.state = extObjFactory.createContext();
        }

        ScreenTranslationsService.prototype = {
            search: function(criteria, queryParams) {

                return $http.get('api/configuration/system/mui/search', {
                        params: {
                            q: JSON.stringify(criteria),
                            params: JSON.stringify(queryParams)
                        }
                    })
                    .then(function(response) {
                        var result = response.data;
                        result.data = _.map(response.data.data, function(item) {
                            return angular.extend(item, {
                                areaKey: 'screenlabels.area.' + (item.area || 'common'),
                                translation: item.translation || null
                            });

                        });
                        return result;
                    });
            },

            getOrAttach: function(item) {
                var self = this;
                return self.state.find(item.id) || self.state.attach(item);
            },

            save: function(languageCode) {
                var self = this;
                var items = self.state.getDirtyItems();
                var newValues = items.map(function(a) {
                    return {
                        key: a.id,
                        value: a.translation
                    };
                });

                var changes = {
                    languageCode: languageCode,
                    translations: newValues
                };

                return $http.put('api/configuration/system/mui', changes)
                    .then(function(response) {
                        self.state.save();
                        return response.data;
                    });
            },

            isDirty: function() {
                return this.state.isDirty();
            },

            discard: function() {
                this.state.restore();
            },

            reset: function() {
                this.state = extObjFactory.createContext();
            },

            find: function(id) {
                return this.state.find(id);
            },

            hasError: function() {
                return this.state.hasError();
            },

            download: function() {
                window.location = 'api/configuration/system/mui/export';
            }
        };

        return ScreenTranslationsService;
    });
