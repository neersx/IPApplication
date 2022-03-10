(function() {
    'use strict';
    angular.module('inprotech.api.extensions')
        .factory('dirtyCheck', function(restmod) {
            return restmod.mixin('DirtyModel', {
                $extend: {
                    Resource: {
                        $isDirty: function() {
                            if (this.$isCollection) {
                                return _.any(this, function(e) {
                                    return e.$dirty().length > 0 || e.$isNewOrDeleted();
                                });
                            }
                            return this.$dirty().length > 0;
                        },

                        $setPristine: function() {
                            var original = this.$cmStatus = {};
                            this.$each(function(value, key) {
                                original[key] = value;
                            });
                        }
                    },
                    Collection: {
                        $filterOutUnchanged: function() {
                            _.each(this, function(e){
                                e.$dirty();
                            });
                            var filteredData = _.filter(this, function(c) {
                                return c.state !== 'none' && !c.$isFakeDelete();
                            });

                            return this.$collection().$unwrap(filteredData);
                        }
                    },
                    Record: {
                        $dirty: function(param) {
                            var result = this.$super(param);
                            if (angular.isArray(result)) {
                                return _.difference(result, ['state']);
                            }
                            return result;
                        },
                        $isNewOrDeleted: function() {
                            return this.state === 'added' || this.state === 'deleted';
                        },
                        $isNew: function() {
                            return this.id == null;
                        },
                        $isFakeDelete: function() {
                            return this.$isNew() && this.state === 'deleted';
                        }
                    }
                }
            });
        });
})();
