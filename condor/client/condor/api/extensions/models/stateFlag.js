(function() {
    'use strict';
    angular.module('inprotech.api.extensions')
        .factory('stateFlag', function(restmod) {
            return restmod.mixin('dirtyCheck', {
                state: {
                    init: 'none'
                },
                $extend: {
                    Resource: {
                        $markDeleted: function() {
                            if (this.$isCollection) {
                                _.each(this, function(e) {
                                    if (e.marked) {
                                        e.state = 'deleted';
                                    }
                                });
                            } else {
                                this.state = 'deleted';
                            }
                        },
                        $build: function() {
                            var newRecord = this.$super();
                            newRecord.state = 'added';
                            return newRecord;
                        }
                    },
                    Record: {
                        $revertDelete: function() {
                            this.state = 'none';
                            this.error = '';
                            this.$dirty();
                        },
                        $dirty: function(param) {
                            var result = this.$super(param);
                            if (this.state === 'none' || this.state === 'saved') {
                                if (this.$isNew()) {
                                    this.state = 'added';
                                } else if (angular.isArray(result) && result.length > 0) {
                                    this.state = 'updated';
                                }
                            } else if (this.state === 'updated') {
                                if (angular.isArray(result) && result.length === 0) {
                                    this.state = 'none';
                                }
                            }
                            return result;
                        }
                    }
                }
            });
        });
})();
