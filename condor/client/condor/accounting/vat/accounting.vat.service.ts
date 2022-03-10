'use strict';
namespace inprotech.accounting.vat {
    export interface IVatReturnsService {
        initialiseHmrcHeaders(deviceId?: string): ng.IPromise<any>;
        getObligations(data: any);
        getVatData(vatBoxNumber: number, entityNameNo: number, fromDate: Date, toDate: Date);
        submitVatData(data: any);
        save(data: any);
        getReturn(data: any);
        getLogs(entityId: number, periodId: string);
    }

    export class VatReturnsService implements IVatReturnsService {
        static $inject: string[] = ['$http', 'store', 'HmrcHeadersBuilderService'];

        constructor(private $http: ng.IHttpService, private store: any, private headerService: IHmrcHeadersBuilderService) {}

        initialiseHmrcHeaders(deviceId?: string): ng.IPromise<any> {
            return this.headerService.initialise(deviceId)
        }

        getObligations(data: any) {
            return this.$http
                .get('api/accounting/vat/obligations', {
                    params: {
                        q: JSON.stringify(data)
                    },
                    headers: this.getHeaders()
                })
                .then((resp: any) => {
                    if (angular.isDefined(resp.data.result) && resp.data.result.readyToRedirect === 'ok') {
                        return resp.data.result
                    }
                    if (resp.status === 200) {
                        return resp.data.data.data;
                    }
                }, () => {
                    return [];
                });
        }

        private getHeaders = () => {
            return this.headerService.resolve();
        };

        getVatData(vatBoxNumber: number, entityNameNo: number, fromDate: Date, toDate: Date) {
            return this.$http
                .get('api/accounting/vat/vatData', {
                    params: {
                        q: JSON.stringify({
                            vatBoxNumber: vatBoxNumber,
                            entityNameNo: entityNameNo,
                            fromDate: fromDate,
                            toDate: toDate
                        })
                    }
                })
                .then((resp: any) => {
                    return resp.data;
                });
        };

        save(data: any) {
            return this.$http.post('api/accounting/vat/settings/save', data);
        };

        submitVatData(data: any) {
            let payload = angular.extend(data);
            return this.$http
                .post('api/accounting/vat/submit', payload, {
                    headers: this.getHeaders()
                }).then((resp: any) => {
                    if (resp.status === 200) {
                        return resp.data;
                    }
                }, (errors: any) => {
                    return errors.data;
                });
        };

        getReturn(data: any) {
            return this.$http.get('api/accounting/vat/vatreturn', {
                params: {
                    q: JSON.stringify(data)
                },
                headers: this.getHeaders()
            }).then((resp: any) => {
                if (resp.status === 200) {
                    return resp.data;
                }
            }, (errors: any) => {
                return errors.data;
            });
        };

        getLogs(entityId: number, periodId: string) {
            return this.$http.get('api/accounting/vat/vatlogs', {
                params: {
                    q: JSON.stringify({
                        vatNo: entityId,
                        periodKey: periodId
                    })
                }
            }).then((resp: any) => {
                return resp.data;
            });
        };
    }

    angular.module('inprotech.accounting.vat')
        .service('VatReturnsService', VatReturnsService);
}