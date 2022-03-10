'use strict';
namespace inprotech.portfolio.cases {
  export class CaseviewClassesController implements ng.IController {
    static $inject = [
      '$scope',
      'kendoGridBuilder',
      'localSettings',
      'caseviewClassesService',
      'dateService',
      '$timeout'
    ];
    public vm: CaseviewClassesController;
    public classesData: any;
    public viewData: any;
    public gridOptions: any;
    public topic: any;
    public classesList: any;
    public enableRichText: boolean;

    constructor(
      public $scope: any,
      public kendoGridBuilder: any,
      private localSettings: inprotech.core.LocalSettings,
      private service: ICaseviewClassesService,
      private dateService,
      private $timeout: any
    ) {
      this.vm = this;
    }

    $onInit() {
      this.gridOptions = this.buildGridOptions();
      this.viewData.enableRichText = this.enableRichText;
      this.service.getClassesSummary(this.viewData.caseKey).then(res => {
        this.vm.viewData.classesData = res;
      });
    }

    private getPageNumberLocalSetting = () => {
      return this.localSettings.Keys.caseView.classes.pageNumber;
    };

    private getColumnSelectionLocalSetting = () => {
      return this.localSettings.Keys.caseView.classes.columnsSelection;
    };

    private setGridOptionsForClasses = gridOptions => {
      gridOptions.columns.push(
        {
          title: 'caseview.classes.gstText',
          field: 'gsText',
          template:
            '<span ng-if="vm.enableRichText === true" ng-bind-html="::dataItem.gsText | html"></span><div ng-if="vm.enableRichText !== true" style="white-space: pre-wrap;">{{::dataItem.gsText}}</div>',
          encoded: true,
          fixed: false,
          menu: true,
          hidden: false
        },
        {
          title: 'caseview.classes.firstUse',
          field: 'dateFirstUse',
          template:
            '<span>{{ dataItem.dateFirstUse | date:"' +
            this.dateService.dateFormat +
            '" }}</span>',
          encoded: true,
          menu: true,
          sortable: true,
          hidden: true,
          width: '20%'
        },
        {
          title: 'caseview.classes.firstUseInCommerce',
          field: 'dateFirstUseInCommerce',
          template:
            '<span>{{ dataItem.dateFirstUseInCommerce | date:"' +
            this.dateService.dateFormat +
            '" }}</span>',
          encoded: true,
          menu: true,
          sortable: true,
          hidden: true,
          width: '20%'
        }
      );
      return gridOptions;
    };

    public buildGridOptions = (): any => {
      let options = {
        id: 'caseViewClasses',
        autoBind: true,
        navigatable: true,
        sortable: true,
        reoderable: true,
        selectOnNavigate: true,
        pageable: {
          pageSize: this.getPageNumberLocalSetting().getLocal
        },
        read: queryParams => {
          return this.service
            .getClassesDetails(this.viewData.caseKey, queryParams)
            .then((res: any) => {
              this.classesList = res;
              return res;
            });
        },
        onPageSizeChanged: pageSize => {
          this.getPageNumberLocalSetting().setLocal(pageSize);
        },
        autoGenerateRowTemplate: true,
        topicItemNumberKey: this.topic.key,
        columns: this.getColumns(),
        columnSelection: {
          localSetting: this.getColumnSelectionLocalSetting()
        },
        showExpandIfCondition: 'dataItem.class',
        dataBound: (e) => {
          this.$timeout(this.expandRow, 10, true, e);
        },
        detailTemplate: '<ip-class-texts view-data="::dataItem" parent-view-data="vm.viewData"></ip-class-texts>'
      };

      options = this.setGridOptionsForClasses(options);
      return this.kendoGridBuilder.buildOptions(this.$scope, options);
    };

    private expandRow = (e) => {
      let grid = e.sender;
      grid.items().each(function (idx, item) {
        let dataItem = grid.dataItem(item);
        if (dataItem.hasMultipleLanguageClassText) {
          grid.expandRow(grid.tbody.find('tr.k-master-row:eq(' + idx + ')'));
        }
      });
    }

    private getColumns = (): any => {
      let columns = [
        {
          title: 'caseview.classes.class',
          field: 'class',
          fixed: true,
          menu: false,
          hidden: false
        },
      ];

      if (!this.viewData.usesDefaultCountryForClasses) {
        columns.splice(1, 0, {
          title: 'caseview.classes.InternationalEquivalent',
          field: 'internationalEquivalent',
          fixed: true,
          menu: true,
          hidden: true
        });
      }
      if (this.viewData.allowSubClassWithoutItem) {
        columns.splice(1, 0, {
          title: 'caseview.classes.subClass',
          field: 'subClass',
          fixed: true,
          menu: true,
          hidden: false
        });
      }
      return columns;
    };
  }

  class CaseviewClassesComponent implements ng.IComponentOptions {
    public controller: any;
    public controllerAs: string;
    public templateUrl: string;
    public bindings: any;
    public viewData: any;
    public enableRichText: any;
    constructor() {
      this.controller = CaseviewClassesController;
      this.controllerAs = 'vm';
      this.templateUrl = 'condor/portfolio/cases/classes/classes.html';
      this.bindings = {
        viewData: '<',
        enableRichText: '<',
        topic: '<'
      };
    }
  }
  angular
    .module('inprotech.portfolio.cases')
    .component('ipCaseviewClasses', new CaseviewClassesComponent());
}
