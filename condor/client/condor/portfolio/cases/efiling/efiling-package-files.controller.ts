'use strict'
namespace inprotech.portfolio.cases {
    export class CaseViewEfilingPackageFilesController implements ng.IController {
        static $inject = ['$scope', 'eFilingPreview', 'kendoGridBuilder', 'CaseviewEfilingService'];
        public vm: CaseViewEfilingPackageFilesController;
        public gridOptions: any;
        exchangeId: number;
        packageSequence: number;
        caseKey: number;

        constructor(private $scope: any, public eFilingPreview: IEfilingPreview, private kendoGridBuilder: any, public service: ICaseviewEfilingService) {
            this.vm = this;
            this.eFilingPreview = eFilingPreview;
        }

        $onInit() {
            this.gridOptions = this.buildGridOptions();
        }

        public buildGridOptions = (): any => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'eFilingPackageFiles',
                autoBind: true,
                pageable: false,
                autoGenerateRowTemplate: true,
                sortable: {
                    allowUnsort: true
                },
		        reorderable: false,
                read: () => {
                    return this.service.getPackageFiles(this.caseKey, this.exchangeId, this.packageSequence);
                },
                columns: this.getColumns()
            });
        }

        private getColumns = (): any => {
            return [{
                title: 'caseview.eFilingPackageFiles.description',
                field: 'componentDescription',
                oneTimeBinding: true
            }, {
                title: 'caseview.eFilingPackageFiles.name',
                field: 'fileName',
                template: '<a ng-if="::dataItem.fileSize" ng-click="vm.clickFile(vm.caseKey, vm.packageSequence, dataItem.packageFileSequence, vm.exchangeId)" ng-class="pointerCursor" ng-bind="::dataItem.fileName" uib-tooltip="{{::\'caseview.eFilingPackageFiles.fileAvailable\' | translate }}" tooltip-class="tooltip-info"></a>' +
                    '<span ng-if="::!dataItem.fileSize" uib-tooltip="{{::\'caseview.eFilingPackageFiles.fileUnavailable\' | translate }}" tooltip-class="tooltip-info">{{::dataItem.fileName}}</span>',
                oneTimeBinding: true
            }, {
                title: 'caseview.eFilingPackageFiles.size',
                field: 'fileSize',
                oneTimeBinding: true
            }, {
                title: 'caseview.eFilingPackageFiles.type',
                field: 'fileType',
                oneTimeBinding: true
            }];
        }

        public clickFile = (caseKey: number, packageSequence: number, packageFileSequence: number, exchangeId: number): any => {
            let previewService = this.eFilingPreview;
            this.service.getEfilingFileData(caseKey, packageSequence, packageFileSequence, exchangeId)
                .then(function(response) {
                    previewService.preview(response);
                });
        };
    }

    class CaseViewEfilingPackageFilesComponent implements ng.IComponentOptions {
        public controller: any;
        public controllerAs: string;
        public templateUrl: string;
        public bindings: any;
        constructor() {
            this.controller = CaseViewEfilingPackageFilesController;
            this.controllerAs = 'vm';
            this.templateUrl = 'condor/portfolio/cases/efiling/efiling-package-files.html';
            this.bindings = {
                exchangeId: '<',
                packageSequence: '<',
                caseKey: '<'
            }
        }
    }
    angular.module('inprotech.portfolio.cases')
        .component('ipCaseViewEfilingPackageFiles', new CaseViewEfilingPackageFilesComponent());
}