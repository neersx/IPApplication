
class MainContentController implements ng.IController {
    static $inject = ['$scope', 'splitterBuilder', 'menuBuilder', 'menuService', 'store', 'appContext'];

    public splitterDetails: SplitterDetails;
    public menuDetails: MenuDetails;
    public leftBarExpanded = false;
    leftBarExpandedChoice = 'portal.leftbar.expanded';

    constructor(private $scope: ng.IScope, private splitterBuilder: ISplitterBuilder, private menuBuilder: IMenuBuilder, private menuService: MenuService, private store: any, private appContext: any) {
        this.init();

        this.$scope.$watch(() => { return this.leftBarExpanded; }, (newVal, oldVal) => {
            if (newVal !== oldVal) {
                if (newVal) {
                    this.splitterDetails.resizePane('leftBar', '160px');
                } else {
                    this.splitterDetails.resizePane('leftBar', '40px');
                }

                const kotEle = document.getElementsByClassName('kot-content')[0];
                if (kotEle) {
                    this.resizeKotPanel(kotEle, this.leftBarExpanded);
                }

                const topicElement = document.getElementsByTagName('ipx-topic-resolver')[0];
                const lockedGridEle = document.getElementsByClassName('k-grid-content-locked')[0];

                if (topicElement && lockedGridEle) {
                    this.resizeScrollableTopicGrid(lockedGridEle, this.leftBarExpanded);
                }

                this.store.local.set(this.leftBarExpandedChoice, newVal);
            }
        });

        this.$scope.$watch(() => { return angular.element(document.getElementsByClassName('kot-content')[0]).is(':visible') }, () => {
            const kotEle = document.getElementsByClassName('kot-content')[0];
            if (this.leftBarExpanded) {
                angular.element(kotEle).css('width', kotEle.clientWidth - 104);
                angular.element(kotEle).css('margin-left', 122 + 'px');
            }
        });

        let context = this;
        this.appContext.then(function (data) {
            context.store.local.default(context.leftBarExpandedChoice, false);
            context.leftBarExpanded = context.store.local.get(context.leftBarExpandedChoice) || false;
        });
    }

    resizeKotPanel = (kotEle: any, isLeftMenuOpened: boolean): void => {
        const currentWidth = kotEle.clientWidth;
        if (isLeftMenuOpened) {
            angular.element(kotEle).css('width', currentWidth - 104);
            angular.element(kotEle).css('margin-left', 122 + 'px');
        } else {
            angular.element(kotEle).css('width', currentWidth + 136);
            angular.element(kotEle).css('margin-left', 2 + 'px');
        }
    }

    resizeScrollableTopicGrid = (lockedGridEle: any, isLeftMenuOpened: boolean): void => {
        const gridEle = document.getElementsByClassName('k-grid-header')[0];
        if (gridEle) {
            const gridUnlockedHeaderEle = document.getElementsByClassName('k-grid-header-wrap')[0];
            const unlokcedGridWidth = gridEle.clientWidth - lockedGridEle.clientWidth;
            const scrollableElement = document.getElementsByClassName('k-grid-content k-virtual-content')[0];

            angular.element(scrollableElement).css('width', unlokcedGridWidth);
            angular.element(gridUnlockedHeaderEle).css('width', unlokcedGridWidth);
        }
    }

    public init = (): void => {
        let leftBarPane: kendo.ui.SplitterPane = {
            collapsible: false,
            collapsed: false,
            resizable: false,
            size: '40px',
            min: '40px',
            max: '160px'
        };

        let mainContentPane: kendo.ui.SplitterPane = {
            collapsible: false,
            resizable: false,
            scrollable: false
        };

        let rightBarPane: kendo.ui.SplitterPane = {
            collapsible: false,
            resizable: false,
            scrollable: false,
            size: '40px'
        };

        this.splitterDetails = this.splitterBuilder.BuildOptions('mainContent', {
            panes: [leftBarPane, mainContentPane, rightBarPane]
        });

        let context = this;
        this.menuService.build().then(function (dataSource) {
            context.menuDetails = context.menuBuilder.BuildOptions('mainMenu', { dataSource: dataSource });
        });
    }
}

class MainContent implements ng.IComponentOptions {
    public bindings: any;
    public controller: any;
    public templateUrl: string;
    public restrict: string;
    transclude: boolean;
    controllerAs: string;

    constructor() {
        this.bindings = {};
        this.transclude = false;
        this.restrict = 'EA';
        this.templateUrl = 'condor/portal/main-content.html';
        this.controller = MainContentController;
        this.controllerAs = 'vm';
    }
}

angular.module('inprotech.portal')
    .component('mainContent', new MainContent());
