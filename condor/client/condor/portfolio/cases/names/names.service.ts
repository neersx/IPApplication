'use strict'
namespace inprotech.portfolio.cases {

    export interface ICaseviewNamesService {
        getNames(caseKey: number, nameTypes: string[], screenCriteriaKey: number, queryParams: any): ng.IPromise<any[]>;
        getFirstEmailTemplate(caseKey: number, nameType: string, sequence?: number): ng.IPromise<inprotech.components.form.EmailTemplate>
    }

    class CaseviewNamesService implements ICaseviewNamesService {
        constructor(private $http: ng.IHttpService) {}

        getNames = (caseKey: number, nameTypes: string[], screenCriteriaKey: number, queryParams: any): ng.IPromise<any[]> => {
            return this.$http.get('api/case/' + caseKey + '/names', {
                params: {
                    params: JSON.stringify(queryParams),
                    screenCriteriaKey: screenCriteriaKey,
                    nameTypes: JSON.stringify({
                        keys: nameTypes
                    })
                }
            }).then((resp: any) => {
                return resp.data;
            });
        };

        getFirstEmailTemplate = (caseKey: number, nameType: string, sequence: number = null): ng.IPromise<inprotech.components.form.EmailTemplate> => {
            return this.$http.get('api/case/' + caseKey + '/names/email-template', {
                params: {
                    params: JSON.stringify({
                        caseKey: caseKey,
                        nameType: nameType,
                        sequence: sequence
                    }),
                    resolve: sequence == null
                }
            }).then((resp: any) => {
                return (resp.data || []).length >= 1 ? resp.data[0] : null;
            });
        };
    }

    angular.module('inprotech.portfolio.cases')
        .service('caseviewNamesService', ['$http', CaseviewNamesService])
}