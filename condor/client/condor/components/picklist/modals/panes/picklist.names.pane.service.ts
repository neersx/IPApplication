'use strict';
namespace inprotech.components.picklist {
    export interface IPicklistNamesPaneService {
        getName(nameId: number);
    }

    export class PicklistNamesPaneService implements IPicklistNamesPaneService {
        static $inject: string[] = ['$http'];

        constructor(private $http: ng.IHttpService) {}

        getName(nameId: number) {
            return this.$http
                .get('api/picklists/names/' + encodeURI(nameId.toString()))
                .then(response => response.data);
        }
    }

    angular.module('inprotech.components.picklist')
        .service('PicklistNamesPaneService', PicklistNamesPaneService);
}