class ClassItemsController {
  static $inject = ['$scope', 'states', '$http'];
  public availableSubClasses: any;

  constructor(
    private $scope: any,
    private states: any,
    private $http: ng.IHttpService
  ) {
    this.initViewData();
    this.$scope.vm.onBeforeSave = this.onBeforeSave;
  }

  initViewData = () => {
    if (this.$scope.vm.maintenanceState === this.states.adding) {
      this.$scope.vm.entry.class = this.$scope.vm.initialViewData.class;
      this.$scope.vm.entry.subClass = this.$scope.vm.initialViewData.subClass;
      this.$scope.vm.entry.country = this.$scope.vm.initialViewData.countryCode;
      this.$scope.vm.entry.propertyType = this.$scope.vm.initialViewData.propertyType;
    }
    if (this.subClassSelectable()) {
      this.subclasses();
    }
  };

  subClassSelectable = (): Boolean => {
    return _.isEmpty(this.$scope.vm.initialViewData.subClass);
  };

  onBeforeSave = entry => {
    if (
      (!_.isEmpty(entry.subClass) && _.isEmpty(entry.itemNo)) ||
      (_.isEmpty(entry.itemNo) && !_.isEmpty(entry.language))
    ) {
      this.$scope.vm.maintenance.itemno.$setValidity('required', false);
      return;
    } else {
      this.$scope.vm.saveWithoutValidate();
    }
  };

  subclasses = () => {
    this.$http
      .get(
        'api/picklists/classitems/subclasses/' +
        this.$scope.vm.initialViewData.countryCode +
        '/' +
        this.$scope.vm.initialViewData.propertyType +
        '/' +
        this.$scope.vm.initialViewData.class
      )
      .then(response => {
        this.availableSubClasses = response.data;
      });
  };

  languageDisabled = () => {
    return (
      (this.$scope.vm.maintenanceState === this.states.updating &&
        this.$scope.vm.entry &&
        this.$scope.vm.entry.isDefaultItem) ||
      this.$scope.vm.maintenanceState === this.states.viewing
    );
  };

  isItemNoDisabled = () => {
    return (
      (this.$scope.vm.entry &&
        !this.$scope.vm.entry.subClass &&
        !this.$scope.vm.entry.language) ||
      this.$scope.vm.maintenanceState === this.states.viewing
    );
  };

  onLanguageChange = () => {
    if (!this.$scope.vm.entry.language && !this.$scope.vm.entry.subClass) {
      this.$scope.vm.entry.itemNo = null;
    }
    this.$scope.vm.maintenance.itemno.$setValidity('required', true);
  };

  onSubClassChange = () => {
    this.$scope.vm.entry.itemNo = null;
    this.$scope.vm.maintenance.itemno.$setValidity('required', true);
  };
}

angular
  .module('inprotech.picklists')
  .controller('classItemsController', ClassItemsController);
