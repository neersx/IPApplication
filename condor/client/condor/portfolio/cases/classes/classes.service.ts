'use strict';
namespace inprotech.portfolio.cases {
  export interface ICaseviewClassesService {
    getClassesSummary(caseKey: number): ng.IPromise<any[]>;
    getClassesDetails(caseKey: number, queryParams: any): ng.IPromise<any[]>;
    getClassTexts(caseKey: number, classKey: any): ng.IPromise<any[]>;
  }

  class CaseviewClassesService implements ICaseviewClassesService {
    constructor(private $http: ng.IHttpService) {}

    getClassesSummary = (caseKey: number): ng.IPromise<any[]> => {
      return this.$http
        .get('api/case/' + caseKey + '/classesSummary')
        .then((resp: any) => {
          return resp.data;
        });
    };

    getClassesDetails(
      caseKey: number,
      queryParams: any
    ): angular.IPromise<any[]> {
      return this.$http
        .get('api/case/' + caseKey + '/classesDetails', {
          params: {
            params: JSON.stringify(queryParams)
          }
        })
        .then((resp: any) => {
          return resp.data;
        });
    }

    getClassTexts = (caseKey: Number, classKey: string): ng.IPromise<any> => {
      return this.$http.get('api/case/' + encodeURI(caseKey.toString()) + '/' + encodeURI(classKey.toString()) + '/classTexts')
          .then(response => response.data);
    }
  }

  angular
    .module('inprotech.portfolio.cases')
    .service('caseviewClassesService', ['$http', CaseviewClassesService]);
}
