angular.module('inprotech.components.grid').factory('inlineEdit', function() {
    'use strict';

    return {
        hasError: function(items) {
            if (!items || !items.length) {
                return false;
            }

            return _.any(items, function(item) {
                return item.hasError();
            });
        },
        canSave: function(items) {
            if (!items || !items.length) {
                return false;
            }

            return _.any(items, function(item) {
                return item.added || item.deleted || item.isDirty();
            });
        },
        createDelta: function(items, mapFunc) {
            return {
                added: _.chain(items).filter(isAdded).map(mapFunc).value(),
                deleted: _.chain(items).filter(isDeleted).map(mapFunc).value(),
                updated: _.chain(items).filter(isUpdated).map(mapFunc).value()
            };
        },
        defineModel: function(props) {
            var propNames = [];
            var propsMap = {};

            _.each(props, function(prop) {
                if (_.isString(prop)) {
                    propNames.push(prop);
                } else {
                    /* name, equals*/
                    propNames.push(prop.name);
                    propsMap[prop.name] = prop;
                }
            });

            function equals(propName, objA, objB) {
                if (objA == null || objB == null) {
                    return objA == objB;
                }

                if (objA[propName] == null || objB[propName] == null) {
                    return objA[propName] == objB[propName];
                }

                if (propsMap[propName] && propsMap[propName].equals) {
                    return propsMap[propName].equals(objA[propName], objB[propName]);
                }

                return angular.equals(objA[propName], objB[propName]);
            }

            return function(raw) {
                raw = raw || {
                    added: true
                };
                var errors = {};
                var obj = angular.extend({}, raw, {
                    error: function(name, value) {
                        if (value == null) {
                            return errors[name];
                        }

                        errors[name] = value;
                    },
                    hasError: function() {
                        return _.any(errors, _.identity);
                    },
                    isDirty: function(propName) {
                        var self = this;
                        if (propName == null) {
                            return _.any(propNames, function(key) {
                                return !equals(key, self, raw);
                            });
                        }

                        return !equals(propName, self, raw);
                    }
                });

                return obj;
            };
        }
    };

    function isAdded(data) {
        return data.added && !data.deleted;
    }

    function isDeleted(data) {
        return data.deleted;
    }

    function isUpdated(data) {
        return !data.deleted && !data.added && data.isDirty();
    }
});