'use strict';
namespace inprotech.portfolio.cases {
    export interface ICaseviewEfilingService {
        getPackages(caseKey: number, queryParams: any);
        getPackageFiles(caseKey: number, exchangeId: number, packageSequence: number);
        getEfilingFileData(caseKey: number, packageSequence: number, packageFileSequence: number, exchangeId: number);
        getPackageHistory(caseKey: number, exchangeId: number, queryParams: any);
    }

    export class CaseviewEfilingService implements ICaseviewEfilingService {
        static $inject: string[] = ['$http'];

        constructor(private $http: ng.IHttpService) { }

        getPackages = (caseKey: number, queryParams: any) => {
            return this.$http
                .get('api/case/' + caseKey + '/efiling', {
                    params: {
                        params: JSON.stringify(queryParams)
                    }
                })
                .then((resp: any) => {
                    return resp.data;
                });
        };

        getPackageFiles(caseKey: number, exchangeId: number, packageSequence: number) {
            return this.$http
                .get('api/case/' + caseKey + '/efilingPackageFiles', {
                    params: {
                        package: JSON.stringify({
                            exchangeId: exchangeId,
                            packageSequence: packageSequence
                        })
                    }
                })
                .then((resp: any) => {
                    return resp.data;
                });
        };

        getEfilingFileData(caseKey: number, packageSequence: number, packageFileSequence: number, exchangeId: number) {
            return this.$http
                .get('api/case/' + caseKey + '/efilingPackageFileData', {
                    responseType: 'arraybuffer',
                    params: {
                        packageFileData: JSON.stringify({
                            exchangeId: exchangeId,
                            packageSequence: packageSequence,
                            packageFileSequence: packageFileSequence
                        })
                    }
                })
                .then((resp: any) => {
                    return resp;
                });
        };

        getPackageHistory(caseKey: number, exchangeId: number, queryParams: any) {
            return this.$http
                .get('api/case/' + caseKey + '/efilingHistory', {
                    params: {
                        params: JSON.stringify(queryParams),
                        exchangeId: JSON.stringify(exchangeId)
                    }
                })
                .then((resp: any) => {
                    return resp.data;
                });
        };
    }

    angular.module('inprotech.portfolio.cases')
        .service('CaseviewEfilingService', CaseviewEfilingService);
}