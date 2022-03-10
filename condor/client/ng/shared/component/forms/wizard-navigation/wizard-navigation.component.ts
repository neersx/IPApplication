import { ChangeDetectionStrategy, Component, ComponentFactoryResolver, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { WizardComponentHostDirective } from './wizard-component-host.directive';
import { WizardItem } from './wizard-item';
import { WizardStepComponent } from './wizard-step-component';

@Component({
  selector: 'ipx-wizard-navigation',
  templateUrl: './wizard-navigation.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class WizardNavigationComponent implements OnInit {
  @ViewChild(WizardComponentHostDirective, { static: true }) stepHost: WizardComponentHostDirective;
  @Input() steps: Array<WizardItem>;
  @Output() readonly allStepsComplete = new EventEmitter();
  @Output() readonly cancel = new EventEmitter();

  interval: any;
  componentRef: any;
  errorMessage = '';
  currentStep: number;
  nextStep = (): void => {
    if (this.componentRef) {
      (this.componentRef.instance as WizardStepComponent).onNavigateNext().then(() => {
        if (this.currentStep < this.steps.length - 1) {
          this.changeStep(this.currentStep + 1);
        } else {
          this.allStepsComplete.emit();
        }
      }).catch((reason) => {
        this.errorMessage = reason;
      });
    } else {
      this.changeStep(this.currentStep + 1);
    }

  };
  previousStep = (): void => {
    this.changeStep(this.currentStep - 1);
  };

  constructor(private readonly componentFactoryResolver: ComponentFactoryResolver) {
  }

  ngOnInit(): void {
    this.changeStep(1);
  }

  changeStep(currentStep): void {
    this.errorMessage = '';
    if (currentStep < this.steps.length && currentStep > 0) {
      {
        this.currentStep = currentStep;
        if (this.steps) {
          const stepItem = this.steps[this.currentStep - 1];

          const componentFactory = this.componentFactoryResolver.resolveComponentFactory(stepItem.component);

          const viewContainerRef = this.stepHost.viewContainerRef;
          viewContainerRef.clear();

          this.componentRef = viewContainerRef.createComponent(componentFactory);
          (this.componentRef.instance as WizardStepComponent).title = stepItem.data.title;
          (this.componentRef.instance as WizardStepComponent).cancel.subscribe(() => {
              this.cancel.emit();
          });
        }
      }
    }
  }

  trackStep = (_index: number, step: WizardItem) => step.data.title;
}
