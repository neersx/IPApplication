module inprotech.portfolio.cases {
  'use strict';
  export interface ICaseImageService {
    getImage(imageKey: Number, itemKey: number, maxWidth?: number, maxHeight?: number): any;
  }

  export class CaseImageService implements ICaseImageService {
    static $inject: string[] = ['$http'];
    constructor(private $http: angular.IHttpService) { }
    getImage(imageKey: number, itemKey: number, maxWidth?: number, maxHeight?: number) {
      return this.$http
        .get(
          'api/search/case/image/' +
          encodeURI(imageKey.toString()) + '/' +
          encodeURI(itemKey.toString()) +
          (maxWidth != null
            ? '?maxWidth=' + encodeURI(maxWidth.toString())
            : '') +
          (maxHeight != null
            ? '&maxHeight=' + encodeURI(maxHeight.toString())
            : ''),
          { cache: true }
        )
        .then(response => response.data);
    }
  }

  angular
    .module('inprotech.portfolio.cases')
    .service('CaseImageService', CaseImageService);
}
