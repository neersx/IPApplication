namespace inprotech.portfolio.cases {
  'use strict';

  export interface ICaseSharedService {
    lastSearch?: any;
    ids?: any;
    lastViewedIndex?: number;
    totalRows?: number;
    dict?: any;
    initIds(ids: any): void;
    addToExistingIds(ids: any): void;
    fetchNext(currentIndex: number): void;
    getCaseKeyFromRowKey(rowKey): Number;
    createRowKeyCaseKeyMappings(data: any, skipCount: number): any[];
  }

  export class CaseSharedService implements ICaseSharedService {
    static $inject: string[] = ['$http'];
    public lastSearch?: any;
    public ids?: any;
    public lastViewedIndex?: number;
    public totalRows?: number;
    private rowsPerRequest: number;
    public dict?: any;

    constructor(private $http) {
      this.ids = [];
      this.dict = [];
      this.rowsPerRequest = 200;
    }

    initIds(ids: any) {
      if (this.ids && this.ids.length > 0) {
        return;
      }
      if (ids && ids.length > 0) {
        this.dict = ids;
      }
    }

    addToExistingIds(ids: any) {
      if (this.dict && this.dict.length > 0 && ids && ids.length > 0) {
        if (ids[0].value === undefined) {
          this.dict = this.dict.concat(ids);
        } else {
          let keys = _.pluck(this.dict, 'key');
              ids.forEach(id => {

                let checkKeyExists = function(key) {
                  return key === id.key;
                };

                let keyExists = _.some(keys, checkKeyExists);
                if (!keyExists) {
                  this.dict = this.dict.concat(id);
            }
              });
        }
      }
    }

    fetchNext(currentIndex: number) {
      this.lastSearch.params = _.extend(this.lastSearch.params, {
        skip: currentIndex,
        take: this.rowsPerRequest
      });
      return this.$http
        .post('api/search/case', {
          criteria: this.lastSearch.criteria,
          params: this.lastSearch.params
        })
        .then((response: any) => {
          if (currentIndex >= this.dict.length) {
            this.addToExistingIds(this.createRowKeyCaseKeyMappings(response.data, this.dict.length));
          }
          return this.dict;
        });
    }

    getCaseKeyFromRowKey(rowKey): Number {
      let a = _.find(this.dict, function (item: any) {
        return item.key === rowKey;
      });
      if (a === undefined) {
        return null;
      }
      return a.value;
    }

    createRowKeyCaseKeyMappings(data: any, skipCount: number) {
      let dict = [];
      if (data && data['rows']) {
        data['rows'].forEach(element => {
          dict.push({
            key: element.rowKey.toString(),
            value: element.caseKey
          });
          element.rowKey = element.rowKey.toString();
        });
        if (skipCount === 0) {
          this.dict = dict;
        } else {
          this.dict.push(...dict);
        }
        return this.dict;
      }
      return null;
    }
  }

  angular
    .module('inprotech.portfolio.cases')
    .service('CaseSharedService', CaseSharedService);
}
