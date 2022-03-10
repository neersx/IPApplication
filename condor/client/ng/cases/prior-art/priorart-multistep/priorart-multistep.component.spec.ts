import { ChangeDetectorRefMock } from 'mocks';
import { PriorArtType } from '../priorart-model';
import { PriorArtMultistepComponent } from './priorart-multistep.component';

describe('PriorArtMultistepComponent', () => {
    const cdRef = new ChangeDetectorRefMock();
    let component: PriorArtMultistepComponent;

    beforeEach(() => {
        component = new PriorArtMultistepComponent(cdRef as any);
    });

   it('should create the component', (() => {
        expect(component).toBeTruthy();
    }));

    describe('initialising', () => {
        it('should initialise the context and call the api', (() => {
            component.ngOnInit();
            expect(component.steps[0].id).toBe(1);
            expect(component.steps[0].isDefault).toBe(true);
            expect(component.steps[0].title).toBe('priorart.maintenance.step1.priorArtTitle');
            expect(component.steps[1].id).toBe(2);
            expect(component.steps[1].isDefault).toBeFalsy();
            expect(component.steps[1].selected).toBeFalsy();
        }));

        it('should set the step1 title correctly when ipo prior art', () => {
            component.ngOnInit();
            component.priorArtType = PriorArtType.Ipo;
            expect(component.setStep1Title()).toEqual('priorart.maintenance.step1.priorArtTitle');
        });

        it('should set the step1 title correctly when source prior art', () => {
            component.ngOnInit();
            component.priorArtType = PriorArtType.Source;
            expect(component.setStep1Title()).toEqual('priorart.maintenance.step1.sourceTitle');
        });

        it('should set the step1 title correctly when new source prior art', () => {
            component.ngOnInit();
            component.priorArtType = PriorArtType.NewSource;
            expect(component.setStep1Title()).toEqual('priorart.maintenance.step1.newSourceTitle');
        });

        it('should set the step2 title correctly when not source prior art', () => {
            component.priorArtType = PriorArtType.Ipo;
            component.ngOnInit();
            expect(component.steps[1].title).toEqual('priorart.maintenance.step2.associateSource.stepName');
        });

        it('should set the step2 title correctly when source prior art', () => {
            component.priorArtType = PriorArtType.Source;
            component.ngOnInit();
            expect(component.steps[1].title).toEqual('priorart.maintenance.step2.associatePriorArt.stepName');
        });

        it('should set the step 3 and step 4 titles correctly', () => {
            component.ngOnInit();
            expect(component.steps[2].title).toEqual('priorart.maintenance.step3.title');
            expect(component.steps[3].title).toEqual('priorart.maintenance.step4.title');
        });

    });

});