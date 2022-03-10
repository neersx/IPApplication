import { FormBuilder } from '@angular/forms';
import { PriorArtType } from 'cases/prior-art/priorart-model';
import { PriorArtServiceMock } from 'cases/prior-art/priorart.service.mock';
import { ChangeDetectorRefMock, DateHelperMock, StateServiceMock } from 'mocks';
import { PriorartCreateSourceComponent } from './priorart-create-source.component';

describe('PriorArtMultistepComponent', () => {
    const service = new PriorArtServiceMock();
    const cdRef = new ChangeDetectorRefMock();
    const dateHelper = new DateHelperMock();
    const formBuilder = new FormBuilder();
    let component: PriorartCreateSourceComponent;
    let stateService = new StateServiceMock();
    let localDatePipe: any;

    beforeEach(() => {
        stateService = new StateServiceMock();
        localDatePipe = { transform: jest.fn(d => '10-Dec-2000') };
        component = new PriorartCreateSourceComponent(formBuilder, dateHelper as any, stateService as any, localDatePipe, cdRef as any);
    });

    it('should create the component', (() => {
        expect(component).toBeTruthy();
    }));

    describe('getData', () => {
        it('should return the data to be saved', (() => {
            component.ngOnInit();
            component.formGroup.controls.city.setValue('big city');
            component.formGroup.controls.sourceType.setValue({ id: 22, name: 'big source type' });
            component.formGroup.controls.comments.setValue('big comments');
            expect(component.formGroup.value.sourceType).toEqual({ id: 22, name: 'big source type' });
            expect(component.formGroup.value.city).toEqual('big city');
            expect(component.formGroup.value.comments).toEqual('big comments');
        }));
    });

    describe('toggleSourceType', () => {
        it('should set the correct selectedPriorArtType', (() => {
            component.formGroup = {
                controls: {
                    officialNumber: {
                        setValidators: jest.fn(),
                        clearValidators: jest.fn(),
                        updateValueAndValidity: jest.fn()
                    },
                    title: {
                        setValidators: jest.fn(),
                        clearValidators: jest.fn(),
                        updateValueAndValidity: jest.fn()
                    }
                }
            } as any;
            component.toggleSourceType(PriorArtType.Literature);
            expect(component.selectedPriorArtType).toEqual(PriorArtType.Literature);
        }));
    });

    describe('generateDescription', () => {
        const publishDate = new Date(2000, 12, 10);
        it('should concatenate literature details with commas', () => {
            component.ngOnInit();
            component.formGroup.controls.inventorName.setValue('npl-author');
            component.formGroup.controls.title.setValue('npl-title');
            component.formGroup.controls.publishedDate.setValue(publishDate);
            component.formGroup.controls.referenceParts.setValue('npl-doc-parts');
            component.formGroup.controls.publisher.setValue('npl-publisher');
            component.formGroup.controls.city.setValue('npl-city');
            component.formGroup.controls.country.setValue({key: 'npl', value: 'npl-country'});
            component.generateDescription();
            expect(component.formGroup.value.description).toBe('npl-author, npl-title, 10-Dec-2000, npl-doc-parts, npl-publisher, npl-city, npl-country');
        });
    });
});