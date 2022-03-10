module inprotech.portfolio.cases {
    'use strict';

    export interface IDebtorRestriction {
        debtor: number,
        severity: string,
        description: string
    }

    export interface IDebtorRestrictionsService {
        getRestrictions(nameKey: number): ng.IPromise<IDebtorRestriction>;
    }

    class DebtorRestrictionsService implements IDebtorRestrictionsService {
        private cache: any = {};

        constructor(private $http: ng.IHttpService, private $q: ng.IQService) {}

        getRestrictions = (nameKey: number): ng.IPromise<IDebtorRestriction> => {
            let deferred = this.$q.defer<IDebtorRestriction>();

            let cached = this.cache[nameKey];
            if (cached) {
                deferred.resolve(cached);
            } else {
                this.$http.get('api/names/restrictions', {
                    params: {
                        ids: [nameKey].join(',')
                    }
                }).then((resp: any) => {
                    this.cache[nameKey] = resp.data[0];
                    deferred.resolve(this.cache[nameKey]);
                });
            }

            return deferred.promise;
        }
    }

    angular.module('inprotech.portfolio.cases')
        .service('debtorRestrictionsService', ['$http', '$q', DebtorRestrictionsService])
}