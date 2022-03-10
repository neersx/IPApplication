'use strict';
namespace inprotech.portfolio.cases {
    export interface ICaseViewImagesService {
        getCaseImages(caseKey: number);
    }

    export class CaseViewImagesService implements ICaseViewImagesService {
        static $inject: string[] = ['$http'];

        constructor(private $http: ng.IHttpService) {}

        getCaseImages = (caseKey: number) => {
            return this.$http
                .get('api/case/' + caseKey + '/images')
                .then((resp: any) => {
                    return resp.data;
                });
        };
    }

    angular.module('inprotech.portfolio.cases')
        .service('CaseViewImagesService', CaseViewImagesService);
}