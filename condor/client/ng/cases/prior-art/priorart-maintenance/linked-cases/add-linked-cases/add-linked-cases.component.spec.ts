import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { PriorArtServiceMock } from 'cases/prior-art/priorart.service.mock';
import { BsModalRefMock, ChangeDetectorRefMock, NotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { TranslatedServiceMock } from '../../../../../../signin/src/app/mock/translate-service.mock';
import { AddLinkedCasesComponent } from './add-linked-cases.component';

describe('AddLinkedCasesComponent', () => {
    let component: AddLinkedCasesComponent;
    let bsModalRef: any;
    let maintenanceHelper: any;
    let formBuilder: any;
    let notificationService: any;
    let priorArtService: any;
    let translateService: any;
    let cdRef: any;

    beforeEach(() => {
        bsModalRef = new BsModalRefMock();
        maintenanceHelper = { buildDescription: jest.fn().mockReturnValue('generated-description') };
        formBuilder = new FormBuilder();
        notificationService = new NotificationServiceMock();
        priorArtService = new PriorArtServiceMock();
        translateService = new TranslatedServiceMock();
        cdRef = new ChangeDetectorRefMock();
        component = new AddLinkedCasesComponent(bsModalRef, maintenanceHelper, formBuilder, notificationService, priorArtService, translateService, cdRef);
        component.sourceData = {
            description: 'reference-description',
            sourceId: 5552368
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('hides the modal on close', () => {
        component.cancel();
        expect(bsModalRef.hide).toHaveBeenCalled();
    });

    describe('initialisation', () => {
        it('should set the title and create the form', () => {
            component.ngOnInit();
            expect(maintenanceHelper.buildDescription).toHaveBeenCalledWith(component.sourceData);
            expect(component.title).toBe('generated-description');
            expect(component.formGroup).toBeDefined();
        });
    });

    describe('saving', () => {
        const elementMock = {
            el: {
                nativeElement: {
                    querySelector: jest.fn().mockReturnValue({
                        focus: jest.fn()
                    })
                }
            }
        };
        beforeEach(() => {
            component.ngOnInit();
            spyOn(component.formGroup, 'clearValidators');
            spyOn(component.formGroup, 'reset');
            component.caseListEl = elementMock;
            component.caseFamilyEl = elementMock;
            component.caseReferenceEl = elementMock;
            component.caseNameEl = elementMock;
        });
        it('calls the service with the correct data in request', fakeAsync(() => {
            component.caseReference.setValue({ key: 555 });
            component.caseFamily.setValue({key: 'vvv', value: 'the v family'});
            component.caseLists.setValue({key: 900});
            component.caseName.setValue({key: -9898});
            component.nameType.setValue({code: '~OJ'});
            component.onSave();
            expect(component.formGroup.clearValidators).toHaveBeenCalled();
            expect(priorArtService.createLinkedCases$).toHaveBeenCalledWith({ sourceDocumentId: 5552368, caseKey: 555, caseFamilyKey: 'vvv', caseListKey: 900, nameKey: -9898, nameTypeKey: '~OJ' });
            tick();
            expect(notificationService.success).toHaveBeenCalledTimes(1);
            expect(bsModalRef.hide).toHaveBeenCalled();
        }));
        it('resets the form if adding another', fakeAsync(() => {
            component.caseReference.setValue({ key: 555 });
            component.caseFamily.setValue({ key: 'new-fam', value: 'the new family' });
            component.caseLists.setValue({ key: 987 });
            component.addAnother = true;
            component.onSave();
            tick();
            expect(notificationService.success).toHaveBeenCalledTimes(1);
            expect(component.formGroup.reset).toHaveBeenCalledTimes(1);
            expect(bsModalRef.hide).not.toHaveBeenCalled();
        }));
        it('brings up error when there are duplicates', fakeAsync(() => {
            spyOn(component.caseReference, 'setErrors');
            spyOn(component.caseFamily, 'setErrors');
            spyOn(component.caseLists, 'setErrors');
            spyOn(component.caseName, 'setErrors');
            component.caseReference.setValue({ key: 555, code: 'IRN-555' });
            component.caseFamily.setValue({key: 'vvv', value: 'the v family'});
            component.caseLists.setValue({ key: 123 });
            component.caseName.setValue({ key: 4545 });
            priorArtService.createLinkedCases$ = jest.fn().mockReturnValue(of({isSuccessful: false, isFamilyExisting: true, caseReferenceExists: true, isCaseListExisting: true, isNameExisting: true}));
            component.onSave();
            tick();
            expect(notificationService.success).toHaveBeenCalledTimes(0);
            expect(notificationService.alert).toHaveBeenCalledWith({message: 'priorart.maintenance.step3.linkedCases.messages.caseAlreadyLinked'});
            tick(1000);
            expect(component.caseReference.setErrors).toHaveBeenCalled();
            expect(component.caseFamily.setErrors).toHaveBeenCalled();
            expect(component.caseLists.setErrors).toHaveBeenCalled();
            expect(component.caseName.setErrors).toHaveBeenCalled();
        }));
    });
});
