namespace inprotech.portfolio.cases {
  'use strict';

  export interface IPagingInfo {
    viewStartIndex?: number;
    requestStartPage?: number;
    requestEndPage?: number;
    requestKeysFromServer?: boolean;
    rowsPerBlock?: number;
    setPagingInfo(page: any, availableKeys: number, pageSize: number): void;
  }

  export class CaseSearchPagingInfo implements IPagingInfo {
    viewStartIndex?: number;
    requestStartPage?: number;
    requestEndPage?: number;
    requestKeysFromServer?: boolean;
    rowsPerBlock?: number;

    constructor() {
      this.rowsPerBlock = 200;
      this.requestEndPage = 200,
        this.viewStartIndex = 0;
      this.requestStartPage = 0;
      this.requestKeysFromServer = true;
    }
    setPagingInfo(page: number, availableKeys: number, pageSize: number): void {
      if (!page) {
        page = 1;
      }
      let pageStart = (page - 1) * pageSize;
      let pagesPerBlock = this.rowsPerBlock / pageSize;
      if (pageStart >= availableKeys) {
        pageStart = availableKeys;
        this.requestKeysFromServer = true;
      } else {
        this.requestKeysFromServer = false;
      }
      if (this.requestKeysFromServer) {
        let hasSkippedBlocks = availableKeys + this.rowsPerBlock < (page - 1) * pageSize + this.rowsPerBlock;
        this.viewStartIndex = hasSkippedBlocks ? (page - 1) * pageSize - availableKeys : (page > pagesPerBlock ? (page % pagesPerBlock === 0 ? pagesPerBlock : page % pagesPerBlock) - 1 : page - 1) * pageSize;
        this.requestStartPage = pageStart;
        this.requestEndPage = hasSkippedBlocks ? (page - 1) * pageSize + this.rowsPerBlock : this.rowsPerBlock;
      } else {
        this.viewStartIndex = (page > pagesPerBlock ? (page % pagesPerBlock === 0 ? pagesPerBlock : page % pagesPerBlock) - 1 : page - 1) * pageSize;
        this.requestStartPage = 0;
        this.requestEndPage = this.rowsPerBlock;
      }
    }
  }

  angular
    .module('inprotech.portfolio.cases')
    .service('CaseSearchPagingInfo', CaseSearchPagingInfo);
}