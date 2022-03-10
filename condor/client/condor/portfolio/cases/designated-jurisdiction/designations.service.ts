namespace inprotech.portfolio.cases {

    export interface ICaseViewDesignationsService {
        getCaseViewDesignatedJurisdictions(caseKey: number, queryParams: any): ng.IPromise<any[]>;
        getColumnFilterData(caseKey: number, column, otherFilters): ng.IPromise<any[]>;
        getSummary(caseKey: Number): ng.IPromise<any>;
    }

    class CaseViewDesignationsService implements ICaseViewDesignationsService {
        constructor(private $http: ng.IHttpService) {
        }

        getCaseViewDesignatedJurisdictions = (caseKey: number, queryParams: any): ng.IPromise<any[]> => {
            return this.$http.get('api/case/' + caseKey + '/designatedjurisdiction', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            }).then((resp: any) => {
                return resp.data;
            });
        }

        getColumnFilterData = (caseKey: number, column, otherFilters): ng.IPromise<any[]> => {
            return this.$http.get('api/case/' + caseKey + '/designatedjurisdiction/filterData/' + column.field, {
                params: {
                    columnFilters: JSON.stringify(otherFilters)
                }
            }).then(function (response: any) {
                return response.data;
            });
        }

        getSummary = (caseKey: Number): ng.IPromise<any> => {
            return this.$http.get('api/case/' + encodeURI(caseKey.toString()) + '/designationdetails')
                .then(response => response.data);
        }
    }

    angular.module('inprotech.portfolio.cases')
        .service('caseViewDesignationsService', ['$http', CaseViewDesignationsService])
}