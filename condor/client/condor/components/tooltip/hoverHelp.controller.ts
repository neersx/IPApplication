namespace inprotech.components.tooltip {
    'use strict';

    export class HoverHelpController implements ng.IDirective {
        restrict: string;
        transclude: boolean;
        templateUrl: string;
        scope: any;

        constructor() {
            this.restrict = 'E';
            this.transclude = true;
            this.templateUrl = 'condor/components/tooltip/hoverHelp.html'
            this.scope = {
                'template': '@?',
                'title': '@?',
                'content': '@',
                'placement': '@?'
            }
        }
    }
    angular.module('inprotech.components.tooltip')
        .directive('ipHoverHelp', () => new HoverHelpController());
}
