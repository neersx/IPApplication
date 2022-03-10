angular.module('inprotech.components.page').factory('LastSearch', function($q, pagerHelperService) {
    'use strict';

    function LastSearch(args) {
        if (!args.method) {
            throw new Error('method is required');
        }

        this.method = args.method;
        this.methodName = args.methodName;

        if (Array.isArray(args.args)) {
            this.args = angular.copy(args.args);
        } else {
            this.args = angular.copy(Array.prototype.slice.call(args.args));
        }
    }

    LastSearch.prototype.getPageSize = function() {
        if (this.args && this.args[1]) {
            return this.args[1].take;
        }
    };

    LastSearch.prototype.getPageForId = function(id) {
        return pagerHelperService.getPageForId(this.ids, id, this.getPageSize());
    };

    LastSearch.prototype.setAllIds = function(ids) {
        this.ids = ids.slice(0);
    };

    LastSearch.prototype.getAllIds = function() {
        var self = this,
            promise;
        if (self.ids) {
            promise = $q.when(self.ids);
        } else {
            if (self.args && self.args.length) {
                var queryParams = self.args[self.args.length - 1];
                queryParams.getAllIds = true;
            }

            promise = self.method.apply(self, self.args).then(function(response) {
                var data = response.data || response;
                var ids;
                if (Array.isArray(data)) {
                    ids = data;
                } else {
                    ids = _.pluck(response.data || response, 'id');
                }

                self.setAllIds(ids);
                return ids;
            });
        }

        return promise;
    };

    return LastSearch;
});
