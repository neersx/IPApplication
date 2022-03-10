 'use strict';
 class NavModalController {
     static $inject = ['$scope'];
     constructor(private $scope: ng.IScope) {}
     onNavigate = (newItem): void => {
         this.$scope.$emit('modalChangeView', {
             dataItem: newItem
         });
     }
 }

 class NavModal {
     public bindings: any;
     public controller: any;
     public templateUrl: string;
     controllerAs: string;

     constructor() {
         this.templateUrl = 'condor/configuration/general/navmodal/directives/nav-Modal.html';
         this.controller = NavModalController;
         this.controllerAs = 'vm';
         this.bindings = {
             allItems: '<',
             currentItem: '<',
             hasUnsavedChanges: '<',
             onNavigate: '<',
             hasPagination: '<?'
         };
     }
 }

 angular.module('inprotech.configuration.general.navmodal')
     .component('ipNavModal', new NavModal());