import { fakeAsync, tick } from '@angular/core/testing';
import { PriorArtServiceMock } from 'cases/prior-art/priorart.service.mock';
import { AttachmentModalServiceMock } from 'common/attachments/attachment-modal.service.mock';
import { ChangeDetectorRefMock, DateHelperMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { StateServiceMock } from 'mocks/state-service.mock';
import { QuickNavModel } from 'rightbarnav/rightbarnav.service';
import { RightBarNavServiceMock } from 'rightbarnav/rightbarnavservice.mock';
import { of } from 'rxjs';
import { PriorArtType } from '../priorart-model';
import { PriorArtMultistepComponent } from '../priorart-multistep/priorart-multistep.component';
import { PriorArtMaintenanceComponent } from './priorart-maintenance.component';

describe('PriorArtMultistepComponent', () => {
    const service = new PriorArtServiceMock();
    const cdRef = new ChangeDetectorRefMock();
    let component: PriorArtMaintenanceComponent;
    let hotKeys: {};
    let ipxNotificationService: IpxNotificationServiceMock;
    let notificationService: NotificationServiceMock;
    let stateService: any;
    let dateHelper: DateHelperMock;
    let translateService: any;
    let pageTitleService: any;
    let priorArtHelper: any;
    let rightBarNavService: any;
    let attachmentModalService: any;
    beforeEach(() => {
        hotKeys = {
            add: jest.fn()
        };
        ipxNotificationService = new IpxNotificationServiceMock();
        notificationService = new NotificationServiceMock();
        pageTitleService = {
            setPrefix: jest.fn()
        };
        translateService = {
            instant: jest.fn()
        };
        stateService = new StateServiceMock();
        stateService.go = jest.fn();
        dateHelper = new DateHelperMock();
        priorArtHelper = { buildDescription: jest.fn().mockReturnValue('generated-description'), buildShortDescription: jest.fn().mockReturnValue('shortened-description') };
        rightBarNavService = new RightBarNavServiceMock();
        attachmentModalService = new AttachmentModalServiceMock();
        const multistep = new PriorArtMultistepComponent(cdRef as any);
        component = new PriorArtMaintenanceComponent(service as any, cdRef as any, hotKeys as any, ipxNotificationService as any, notificationService as any, stateService, translateService, dateHelper as any, pageTitleService, priorArtHelper, rightBarNavService, attachmentModalService);
        component.stateParams = {};
        component.priorArtSteps = multistep;
        component.dataDetailComponent = { formGroup: { disable: jest.fn(), reset: jest.fn(), dirty: false} } as any;
    });

    it('should create the component', (() => {
        expect(component).toBeTruthy();
        expect(component.isPageDirty()).toBeFalsy();
        expect(component.isSaveButtonEnabled()).toBeFalsy();
    }));

    it('should initialise and register the context menu', () => {
        const priorArt = {
            priorArtSourceTableCodes: {},
            caseIrn: 'boop case',
            sourceDocumentData: {
                isSourceDocument: true,
                isIpDocument: false
            },
            canViewAttachment: true
        };
        const priorArtId = 88555;
        component.stateParams = { sourceId: priorArtId };
        component.priorArtData = priorArt;
        component.buildSourceDescription = jest.fn();
        component.ngOnInit();
        expect(component.buildSourceDescription).toHaveBeenCalledWith(priorArt.sourceDocumentData);
        expect(rightBarNavService.registercontextuals).toHaveBeenCalledWith(
            expect.objectContaining({ contextAttachments: expect.any(QuickNavModel) }));
    });

    it('should go to step 2 when prioart search is closed if priorart search was opened from maintenance page', () => {
        stateService.params = {goToStep: 2};
        stateService.go = jest.fn();
        component.priorArtSteps.goTo = jest.fn();
        component.ngAfterViewInit();
        expect(component.priorArtSteps.goTo).toHaveBeenCalledWith(2);
    });

    it('should call save correctly when bulk save is pressed', fakeAsync(() => {
        const data = {
            createSource: {
                ignoreDuplicates: false,
                sourceDocument: undefined
            }
        };
        component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Source);
        component.dataDetailComponent = { getData: jest.fn(), selectedPriorArtType: PriorArtType.Source, markAsPristine: jest.fn() } as any;
        const caseKey = 123;
        component.stateParams = { caseKey };
        component.save();

        expect(service.maintainPriorArt$).toHaveBeenCalledWith(data, caseKey, PriorArtType.Source);
        tick();
        expect(notificationService.success).toHaveBeenCalled();
        expect(component.dataDetailComponent.markAsPristine).toHaveBeenCalled();
        expect(stateService.go.mock.calls[0][0]).toBe('referenceManagement');
        expect(stateService.go.mock.calls[0][1]).toEqual(expect.objectContaining({caseKey: 123}));
    }));

    describe('buildSourceDescription', () => {
        it('sets the description to display on header and tab', () => {
            const sourceDocumentData = {
                data: 'some-data'
            };
            component.buildSourceDescription(sourceDocumentData);
            expect(priorArtHelper.buildDescription).toHaveBeenCalledWith(sourceDocumentData);
            expect(priorArtHelper.buildShortDescription).toHaveBeenCalledWith(sourceDocumentData);
            expect(component.source).toEqual('generated-description');
            expect(pageTitleService.setPrefix).toHaveBeenCalledWith('shortened-description');
        });
    });

    describe('getPriorArtType', () => {
        it('should return the correct new source when sourceDocumentData is empty (creating a new source)', () => {
            component.priorArtData = {};
            expect(component.getPriorArtType()).toEqual(PriorArtType.NewSource);
        });

        it('should return the correct prior art type for source', () => {
            component.priorArtData = {
                sourceDocumentData: {
                    isSourceDocument: true,
                    isIpDocument: false
                }
            };
            expect(component.getPriorArtType()).toEqual(PriorArtType.Source);
        });

        it('should return the correct prior art type for ipo', () => {
            component.priorArtData = {
                sourceDocumentData: {
                    isSourceDocument: false,
                    isIpDocument: true
                }
            };
            expect(component.getPriorArtType()).toEqual(PriorArtType.Ipo);
        });

        it('should return the correct prior art type for literature', () => {
            component.priorArtData = {
                sourceDocumentData: {
                    isSourceDocument: false,
                    isIpDocument: false
                }
            };
            expect(component.getPriorArtType()).toEqual(PriorArtType.Literature);
        });
    });

    describe('isSourceType', () => {
        it('should tell you whether the prior art is a source', () => {
            component.priorArtData = {
                sourceDocumentData: {
                    isSourceDocument: true,
                    isIpDocument: false
                }
            };
            expect(component.isSourceType()).toBeTruthy();
        });
        it('should indicate not as source if IPO issued', () => {
            component.priorArtData = {
                sourceDocumentData: {
                    isSourceDocument: false,
                    isIpDocument: true
                }
            };
            expect(component.isSourceType()).toBeFalsy();
        });
        it('should indicate not as source if Literature', () => {
            component.priorArtData = {
                sourceDocumentData: {
                    isSourceDocument: false,
                    isIpDocument: false
                }
            };
            expect(component.isSourceType()).toBeFalsy();
        });
    });

    describe('delete', () => {
        it('should call the delete service correctly', fakeAsync(() => {
            service.deletePriorArt$ = jest.fn().mockReturnValue(of({ result: true}));
            const sourceId = 333;
            ipxNotificationService.openDeleteConfirmModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true) } });
            component.stateParams = { sourceId };
            component.caseIrn = '123 caseIrn';
            component.source = '123 source';
            component.delete();
            tick();
            expect(service.deletePriorArt$).toHaveBeenCalledWith(sourceId);
            tick();
            expect(component.caseIrn).toBeNull();
            expect(component.source).toBeNull();
            expect(component.deleteSuccess).toBeTruthy();
            expect(component.dataDetailComponent.formGroup.disable).toHaveBeenCalled();
            expect(component.dataDetailComponent.formGroup.reset).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
        }));
    });

    it('should reset the form when reverted', () => {
        component.revert();
        expect(component.dataDetailComponent.formGroup.reset).toHaveBeenCalled();
        expect(cdRef.markForCheck).toHaveBeenCalled();
    });

    it('should set page dirty and enable save', () => {
        component.dataDetailComponent = { formGroup: {dirty: true, valid: true}} as any;
        expect(component.isPageDirty()).toBeTruthy();
        expect(component.isSaveButtonEnabled()).toBeTruthy();
        component.dataDetailComponent = { formGroup: { dirty: true, valid: false } } as any;
        expect(component.isPageDirty()).toBeTruthy();
        expect(component.isSaveButtonEnabled()).toBeFalsy();
    });
});