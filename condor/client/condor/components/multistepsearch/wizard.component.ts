module inprotech.components.multistepsearch {
  export class MultiStepSearchController {
    static $inject = ['$scope', 'StepsPersistenceService', '$timeout', '$interval'];

    public options: any;
    public steps: any;
    public operators: any;
    public allowNavigation: boolean;
    private loadSteps: any;

    constructor(private $scope: ng.IScope, private StepsPersistenceService, private $timeout, private $interval) {}

    $onInit() {
      this.init();
    }

    init = () => {
      this.operators = ['AND', 'OR', 'NOT'];

      this.options = this.StepsPersistenceService.topicOptions;

      this.steps = [];

      if (!_.any(this.StepsPersistenceService.steps)) {
        let firstStep = {
          id: this.steps.length + 1,
          isDefault: true,
          operator: '',
          selected: true
        };
        this.steps.push(firstStep);
      } else {
        this.steps = this.StepsPersistenceService.steps;

        this.loadSteps = this.$interval(() => {
          if (_.all(this.options.topics, (t: any) => {
            if (t) {
              return t.isInitialized;
            }
          })) {
            this.$scope.$broadcast('stepsLoaded');
            this.cancelInterval();
          }
        }, 100);
      }
    };

    cancelInterval = () => {
      if (this.loadSteps) {
        this.$interval.cancel(this.loadSteps);
        this.loadSteps = null;
      }
    }

    navigate = value => {
      if (value) {
        let nextStep = -1;
        this.steps.some((step, i) => {
          return step.selected === true ? (nextStep = i + value) : false;
        });

        if (nextStep > -1 && nextStep < this.steps.length) {
          this.goTo(this.steps[nextStep], false);
        }
      }
    };

    addStep = () => {
      let getSelectedStep = this.getSelectedStep();

      if (getSelectedStep) {
        this.StepsPersistenceService.applyStepData(
          getSelectedStep,
          this.options.topics,
          this.steps
        );
      }

      _.each(this.options.topics, (topic: any) => {
        topic.discard();
      });

      this.unselectAll();

      let newStep = {
        id: this.steps.length + 1,
        operator: 'OR',
        selected: true
      };

      this.steps.push(newStep);
      this.checkNavigation();
      this.goTo(newStep, true);
    };

    removeStep = step => {
      let index = this.steps.indexOf(step);
      if (index > -1) {
        this.steps.splice(index, 1);
      }
      this.checkNavigation();
      let nextStep = index > 0 ? index - 1 : 0;
      this.goTo(this.steps[nextStep], true);
    };

    onOperatorChange = index => {
      let operator = this.steps[index].operator;
      this.StepsPersistenceService.updateOperator(index, operator);
    };

    private getSelectedStep = () => {
      let getSelectedStep = _.first(
        _.filter(this.steps, (step: any) => {
          return step.selected === true;
        })
      );
      return getSelectedStep;
    };

    goTo = (step, preventApply) => {
      if (!preventApply) {
        _.each(this.options.topics, (t: any) => {
          if (_.isFunction(t.updateFormData)) {
            t.updateFormData();
          }
        });

        let getSelectedStep = this.getSelectedStep();

        if (getSelectedStep) {
          this.StepsPersistenceService.applyStepData(
            getSelectedStep,
            this.options.topics,
            this.steps
          );
        }
      }

      this.$scope.$broadcast('stepChanged', {
        stepId: step.id
      });

      this.unselectAll();

      step.selected = true;
      this.scroll();
    };

    checkNavigation = () => {
      let width = angular.element(document.getElementById('wizard'))[0]
        .clientWidth;
      this.allowNavigation =
        this.steps.length > 0
          ? this.steps.length * 220 > width || this.steps.length > 4
          : false;
    };

    scroll = () => {
      if (this.allowNavigation) {
        let nextStep = -1;
        this.steps.some(function(step, i) {
          return step.selected === true ? (nextStep = i) : false;
        });

        this.$timeout(() => {
          let current = angular.element(
            document.getElementById('step_' + nextStep)
          );
          if (current) {
            angular
              .element(document.getElementById('wizard-header'))
              .stop()
              .animate(
                {
                  scrollLeft: nextStep * 190
                },
                'slow'
              );
          }
        }, 100);
      }
    };

    private unselectAll = () => {
      angular.forEach(this.steps, function(step) {
        step.selected = false;
      });
    };
  }

  angular.module('inprotech.components.multistepsearch').component('wizard', {
    bindings: {
      name: '@?',
      steps: '=?',
      multistepMode: '='
    },
    templateUrl: 'condor/components/multistepsearch/wizard.html',
    controllerAs: 'vm',
    controller: MultiStepSearchController
  });
}
