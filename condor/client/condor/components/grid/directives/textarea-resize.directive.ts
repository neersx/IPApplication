namespace inprotech.components.grid {
    'use strict';

    export class TextAreaController implements ng.IDirective {
        restrict: string;
        template: string;
        regex: string;
        scope: any;
        lines: any;

        constructor() {
            this.restrict = 'E';
            this.regex = '/\n/g';
            this.template = '<textarea readonly rows="{{content.split(\'\n\').length+1}}">{{content}}</textarea>'
            this.scope = {
                'content': '<'
            }
        }
        link(scope, element): any { }

    }

    angular.module('inprotech.components.tooltip')
        .directive('ipTextArea', () => new TextAreaController());
}
