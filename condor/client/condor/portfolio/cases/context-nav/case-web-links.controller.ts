namespace inprotech.portfolio.cases {
    'use strict';
    class CaseWebLinkController implements ng.IController {
        static $inject: string[] = ['viewData'];

        constructor(public viewData: any[]) {
        }

        public hasCaseLinks = () => {
            return this.viewData && this.viewData.length > 0;
        }
    }
    angular.module('inprotech.portfolio.cases')
        .controller('caseWebLinkController', CaseWebLinkController);
}