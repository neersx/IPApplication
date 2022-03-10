import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ContentChild, Input, OnInit, ViewChild } from '@angular/core';
import * as _ from 'underscore';
import { PriorArtStep, PriorArtType } from '../priorart-model';

@Component({
    selector: 'ipx-priorart-multistep',
    templateUrl: './priorart-multistep.component.html',
    styleUrls: ['./priorart-multistep.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class PriorArtMultistepComponent implements OnInit {
    constructor(private readonly cdr: ChangeDetectorRef) { }
    steps: Array<PriorArtStep>;
    currentStep: PriorArtStep;
    @Input() priorArtType: PriorArtType;
    ngOnInit(): void {
        const firstStep = {
            id: 1,
            selected: true,
            title: this.setStep1Title(),
            isDefault: true
        };
        const secondStep = {
            id: 2,
            selected: false,
            title: this.priorArtType === PriorArtType.Source ? 'priorart.maintenance.step2.associatePriorArt.stepName' : 'priorart.maintenance.step2.associateSource.stepName',
            isDefault: false
        };
        const thirdStep = {
            id: 3,
            selected: false,
            title: 'priorart.maintenance.step3.title',
            isDefault: false
        };
        const fourthStep = {
            id: 4,
            selected: false,
            title: 'priorart.maintenance.step4.title',
            isDefault: false
        };
        const fifthStep = {
            id: 5,
            selected: false,
            title: 'priorart.maintenance.step5.title',
            isDefault: false
        };
        const sixthStep = {
            id: 6,
            selected: false,
            title: 'priorart.maintenance.step6.title',
            isDefault: false
        };
        this.steps = [firstStep];
        if (this.priorArtType !== PriorArtType.NewSource) {
            this.steps.push(secondStep);
            this.steps.push(thirdStep);
            this.steps.push(fourthStep);
        }
        this.currentStep = firstStep;
    }

    goTo = (step: number) => {
        this.steps.map(v => v.selected = false);
        this.steps[step - 1].selected = true;
        this.currentStep = this.steps[step - 1];
        this.cdr.detectChanges();
    };

    trackByFn = (index: number, step: PriorArtStep): any => {
        return step;
    };

    setStep1Title = (): string => {
        if (this.priorArtType === PriorArtType.Source) {
            return 'priorart.maintenance.step1.sourceTitle';
        } else if (this.priorArtType === PriorArtType.NewSource) {
            return 'priorart.maintenance.step1.newSourceTitle';
        }

        return 'priorart.maintenance.step1.priorArtTitle';
    };
}