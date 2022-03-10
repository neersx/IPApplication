import { fakeAsync, tick } from '@angular/core/testing';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { of } from 'rxjs';
import { AttachmentsModalComponent } from './attachments-modal.component';

describe('AttachmentsModalComponent', () => {
    let component: AttachmentsModalComponent;
    let appContext: any;
    let bsModalRef: any;
    let cdRef: any;

    beforeEach(() => {
        appContext = new AppContextServiceMock();
        bsModalRef = new BsModalRefMock();
        cdRef = new ChangeDetectorRefMock();
        component = new AttachmentsModalComponent(appContext, bsModalRef, cdRef);
    });

    describe('initialisation', () => {
        it('should set case-specific view data', () => {
            component.baseType = 'case';
            component.key = -555;
            component.viewData$ = of(null);
            component.ngOnInit();
            expect(component.viewData.baseType).toBe('case');
            expect(component.viewData.key).toBe(-555);
            expect(component.case).toEqual(expect.objectContaining({ key: -555 }));
            expect(component.loaded).toBeFalsy();
        });
        it('should check case attachment maintenance permissions', fakeAsync(() => {
            component.baseType = 'case';
            component.viewData$ = of({ canMaintainCaseAttachments: true, canMaintainPriorArtAttachments: false, canAccessDocumentsFromDms: true });
            component.ngOnInit();
            tick();
            expect(component.viewData.canMaintainAttachment).toBeTruthy();
            expect(component.dmsConfigured).toBeTruthy();
            expect(component.loaded).toBeTruthy();
        }));
        it('should check prior art attachment maintenance permissions', fakeAsync(() => {
            component.baseType = 'priorArt';
            component.key = {
                sourceId: 3,
                caseKey: 5
            };
            component.viewData$ = of({ canMaintainCaseAttachments: false, canMaintainPriorArtAttachments: true, canAccessDocumentsFromDms: true });
            component.ngOnInit();
            tick();
            expect(component.viewData.canMaintainAttachment).toBeTruthy();
            expect(component.dmsConfigured).toBeFalsy();
            expect(component.loaded).toBeTruthy();
            expect(component.case.key).toEqual(5);
            expect(component.viewData.key).toEqual(3);
            expect(component.topic.params.viewData.caseKey).toEqual(5);
        }));
        it('should set showDms to true, if attachments not visible', () => {
            component.baseType = 'case';
            component.viewData$ = of({ canAccessDocumentsFromDms: true, canViewCaseAttachments: false });
            component.ngOnInit();

            expect(component.attachmentsVisible).toBeFalsy();
            expect(component.dmsConfigured).toBeTruthy();
            expect(component.showDms).toBeTruthy();
        });
    });

    describe('closing the modal', () => {
        it('calls modified and hides modal', () => {
            const nextSpy = spyOn(component.dataModified$, 'next');
            component.close();
            expect(nextSpy).toHaveBeenCalledWith(false);
            expect(bsModalRef.hide).toHaveBeenCalled();
        });
    });

});