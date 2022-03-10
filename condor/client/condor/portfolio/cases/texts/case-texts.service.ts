'use strict'
namespace inprotech.portfolio.cases {

    export interface ICaseViewCaseTextsService {
        getTexts(caseKey: number, textTypes: string[], queryParams: any): any;
        getTextHistory(caseKey: number, textType: string, language: any): any;
    }

    class CaseViewCaseTextsService implements ICaseViewCaseTextsService {
        constructor(private $http: ng.IHttpService) {
        }

        getTexts = (caseKey: number, textTypes: string[], queryParams: any): any => {
            return this.$http.get('api/case/' + caseKey + '/texts', {
                params: {
                    params: JSON.stringify(queryParams),
                    textTypes: JSON.stringify({ keys: textTypes })
                }
            }).then((resp: any) => {
                return resp.data;
            });
        }

        getTextHistory = (caseKey: number, textType: string, language: any): any => {
            return this.$http.get('api/case/' + caseKey + '/textHistory', {
                params: {
                    textClass: '',
                    language: language || '',
                    textType: textType || ''
                }
            }).then((resp: any) => {
                return resp.data;
            });
        }
    }

    angular.module('inprotech.portfolio.cases')
        .service('caseViewCaseTextsService', ['$http', CaseViewCaseTextsService])
}