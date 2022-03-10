import { async } from '@angular/core/testing';
import { FormControl, NgForm } from '@angular/forms';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { AdHocDateService, BsModalRefMock, ChangeDetectorRefMock, DateHelperMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { TaskPlannerServiceMock } from 'search/task-planner/task-planner.service.mock';
import { AdHocDateComponent } from './adhoc-date.component';
import { adhocType, adhocTypeMode } from './adhoc-date.service';

describe('AdHocDateComponent', () => {
    let component: AdHocDateComponent;
    const modalRef = new BsModalRefMock();
    const notificationService = new NotificationServiceMock();
    const dateHelper = new DateHelperMock();
    const localSettings = new LocalSettingsMock();
    const taskPlannerService = new TaskPlannerServiceMock();
    const cdr = new ChangeDetectorRefMock();
    const adHocDateService = new AdHocDateService();
    const ipxNotificationService = new IpxNotificationServiceMock();
    beforeEach(() => {
        component = new AdHocDateComponent(modalRef as any, adHocDateService as any
            , notificationService as any, dateHelper as any, cdr as any, taskPlannerService as any, localSettings as any, ipxNotificationService as any);
        component.viewData = { loggedInUser: { key: 1, code: 1, displayName: 'Robert' }, criticalUser: { key: 2, code: 2, displayName: 'Mary' }, defaultAdHocImportance: false };
        component.adhocForm = new NgForm(null, null);
        component.adhocForm.form.addControl('repeatEvery', new FormControl(1));
        component.adhocForm.form.addControl('endOn', new FormControl('date'));
        component.adhocForm.form.addControl('sendreminder', new FormControl({ value: 0, type: 'D' }));
        component.adhocForm.form.addControl('staff', new FormControl(0));
        component.adhocForm.form.addControl('signatory', new FormControl(0));
        component.adhocForm.form.addControl('criticalList', new FormControl(0));
        component.adhocForm.form.addControl('mySelf', new FormControl(0));
        component.adhocForm.form.addControl('nameType', new FormControl(null));
        component.adhocForm.form.addControl('names', new FormControl([]));
        component.adhocForm.form.addControl('relationship', new FormControl(null));
        component.adhocForm.form.addControl('emailSubjectLine', new FormControl(null));
        component.adhocForm.form.addControl('additionalNames', new FormControl([]));
        component.formData = { repeatEvery: 1, endOn: 'date', sendreminder: { value: 5, type: 'M' }, otherNames: [], nameType: { key: 1, code: 1 } };
        component.employeeSignatory = [
            {
                code: 2,
                displayName: 'wadra',
                key: 3,
                type: 'EMP'
            }, {
                code: 4,
                displayName: 'wadra',
                key: 5,
                type: 'EMP'
            }];
        component.caseEventDetails = {
            case: {
                key: 1,
                code: 'AU/1234',
                value: 'Case Title'
            }
        };
        component.adhocDateDetails = {
            alertId: 70206,
            type: 'case',
            adHocDateFor: 'Branch, Bruce John',
            resolveReasons: null,
            employeeNo: 5,
            caseId: null,
            message: 'one hour',
            finaliseReference: 'A68410',
            reference: {
                case: {
                    key: -128,
                    code: 'A68410',
                    value: 'ZAP',
                    officialNumber: null,
                    propertyTypeDescription: null,
                    countryName: null,
                    instructorName: null,
                    instructorNameId: null
                },
                name: null,
                general: null
            },
            dueDate: '2021-09-09T00:00:00',
            dateOccurred: null,
            resolveReason: null,
            deleteOn: '2021-09-10T00:00:00',
            endOn: '2021-09-10T00:00:00',
            monthlyFrequency: null,
            monthsLead: null,
            dailyFrequency: 1,
            daysLead: 1,
            sendElectronically: 1,
            emailSubject: 'asdasda',
            event: null,
            importanceLevel: 9,
            nameNo: null,
            employeeFlag: true,
            signatoryFlag: true,
            criticalFlag: true,
            relationshipValue: {
                key: 'REN',
                code: 'REN',
                value: 'Send Renewals To'
            },
            adhocResponsibleName: {
                type: 'AdhocResponsibleName',
                key: 5,
                code: 'BJB',
                displayName: 'Branch, Bruce John'
            },
            nameTypeValue: {
                key: 'D',
                code: 'D',
                value: 'Debtor'
            }
        };
    });
    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('should initFormData', () => {
        component.initFormData();
        expect(component.formData.adhocType).toEqual('case');
        expect(component.formData.reference).toEqual(component.caseEventDetails);
    });

    it('should initFormData when we do edit', () => {
        component.initFormData();
        expect(adHocDateService.nameDetails).toHaveBeenCalled();
    });

    it('should ngOnInit', () => {
        component.ngOnInit();
        expect(component.formData.adhocType).toEqual('case');
        expect(component.formData.reference).toEqual({
            case: {
                code: 'AU/1234',
                key: 1,
                value: 'Case Title'
            }
        });
    });
    it('should onSave', async(() => {
        component.formData = {
            adhocType: 'case',
            responsibleName: {
                key: -487,
                code: 'GG',
                displayName: 'Grey, George'
            },
            reference: {
                case: {
                    key: -388,
                    code: 'SRB-980501-1',
                    value: 'INPROMA',
                    officialNumber: '1000020',
                    propertyTypeDescription: 'Trademark',
                    countryName: 'United States of America',
                    instructorName: null,
                    instructorNameId: null
                }
            },
            dueDate: '2021-07-30T14:19:34.000Z',
            event: null,
            deleteOn: '2021-07-31T14:19:34.000Z',
            adhocTemplate: null,
            message: 'fgdfgdfg',
            importanceLevel: 3,
            sendreminder: { value: 0, type: 'D' },
            otherNames: []
        };
        const request = {
            employeeNo: -487,
            caseId: -388,
            nameNo: null,
            reference: null,
            dueDate: '2021-07-30',
            alertMessage: 'fgdfgdfg',
            eventNo: null,
            importanceLevel: 3,
            deleteOn: '2021-07-31'

        };
        component.onSave();
        expect(component.isLoading).toEqual(true);
        expect(adHocDateService.saveAdhocDate).toHaveBeenCalled();
        adHocDateService.saveAdhocDate(request).subscribe(r => {
            expect(component.isLoading).toEqual(false);
        });
    }));

    it('should close when savecall is not true', () => {
        component.close();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('should close when savecall is true', () => {
        component.saveCall = true;
        component.close();
        expect(modalRef.hide).toHaveBeenCalled();
        expect(taskPlannerService.onActionComplete$.next).toHaveBeenCalled();
    });

    it('should call clearRecuringControls', () => {
        component.clearRecuringControls();
        expect(component.formData.isRecurring).toEqual(false);
        expect(component.formData.repeatEvery).toEqual(null);
        expect(component.formData.endOn).toEqual(null);
    });

    it('should call clearReminderControls', () => {
        component.formData.names = [];
        component.clearReminderControls();
        expect(component.adhocForm.controls.staff.value).toEqual(0);
        expect(component.adhocForm.controls.signatory.value).toEqual(0);
        expect(component.adhocForm.controls.criticalList.value).toEqual(0);
        expect(component.adhocForm.controls.nameType.value).toEqual(null);
    });

    it('should call bindStaffSignatoryWithNamesPicklist', () => {
        component.caseEventDetails = {
            case: {
                key: 1,
                code: 'AU/1234',
                value: 'Case Title'
            }
        };
        component.initFormData();
        component.bindStaffSignatoryWithNamesPicklist();
        expect(component.formData.names.length).toEqual(3);
    });

    it('should call setReminderModel', () => {
        component.formData.emailSubjectLine = 'xyz@data.com';
        component.setReminderModel();
        expect(component.adhocReminderDetails.emailSubject).toEqual('xyz@data.com');
    });

    it('should call isNameAvailbaleForOtherCheckBox', () => {
        component.caseEventDetails = {
            case: {
                key: 1,
                code: 'AU/1234',
                value: 'Case Title'
            }
        };
        expect(component.isNameAvailbaleForOtherCheckBox(adhocType.criticalList, 1)).toEqual(true);
    });

    it('should call adHocResponsibleChange', () => {
        component.initFormData();
        const event = {
            key: -40,
            code: 'HH',
            displayName: 'Hari',
            type: 'loggedInUser'
        };
        component.adHocResponsibleChange(event);
        expect(component.formData.names[1].displayName).toEqual(event.displayName);
    });
    it('should call caseRefChange', () => {
        component.initFormData();
        const event = {
            key: -40,
            code: 'HH',
            displayName: 'Hari',
            type: 'loggedInUser'
        };
        component.adhocForm.controls.nameType.setValue('1');
        component.adhocForm.controls.relationship.setValue('2');
        component.caseRefChange(event);
        expect(component.adhocForm.controls.nameType.value).toEqual(null);
        expect(adHocDateService.nameDetails).toHaveBeenCalled();
    });
    it('should call nameTypeChange', () => {
        component.initFormData();
        const event = {
            key: -40
        };
        component.formData.names.push({
            type: 'Relationship',
            key: -48,
            code: null,
            displayName: 'Origami, Ken'
        }, {
            type: 'Relationship',
            key: -49,
            code: null,
            displayName: 'Origami, Ken'
        });
        component.nameTypeChange(event);
        expect(component.formData.names.length).toEqual(1);
    });
    it('should display a confirmation modal on adhoc template selection', () => {
        component.ngOnInit();
        const event = { code: 1 };
        component.onTemplateChanged(event);
        expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalled();
    });

    it('should applyAdhocTemplate', () => {
        component.ngOnInit();
        component.formData.adhocTemplate = {
            code: '1231',
            message: 'Adhoc Template',
            daysLead: 1,
            dailyFrequency: 1,
            monthsLead: 2,
            monthlyFrequency: 2,
            stopAlert: 5,
            deleteAlert: 7,
            importanceLevel: 9,
            employeeFlag: true,
            signatoryFlag: true,
            criticalFlag: true,
            sendElectronically: true,
            adhocResponsibleName: {
                type: 'AdhocResponsibleName',
                key: 121,
                code: 'AB',
                displayName: 'Baston, Ann'
            },
            nameTypeValue: {
                key: 'A',
                code: 'A',
                value: 'Agent'
            },
            relationshipValue: {
                key: 'LEA',
                code: 'LEA',
                value: 'Lead'
            },
            emailSubject: 'Subject'
        };
        component.applyAdhocTemplate();
        expect(component.formData.message).toEqual('Adhoc Template');
        expect(component.formData.staff).toEqual(true);
        expect(component.formData.relationship.code).toEqual('LEA');
        expect(component.formData.relationship.value).toEqual('Lead');
        expect(component.formData.responsibleName.displayName).toEqual('Baston, Ann');
    });

    it('should call edit with reminder details', () => {
        component.mode = adhocTypeMode.maintain;
        component.ngOnInit();
        const result = {
            adhocType: 'case',
            responsibleName: {
                type: 'AdhocResponsibleName',
                key: 5,
                code: 'BJB',
                displayName: 'Branch, Bruce John'
            },
            reference: {
                case: {
                    key: -128,
                    code: 'A68410',
                    value: 'ZAP',
                    officialNumber: null,
                    propertyTypeDescription: null,
                    countryName: null,
                    instructorName: null,
                    instructorNameId: null
                },
                name: null,
                general: null
            },
            noReminder: false,
            sendreminder: {
                value: 1,
                type: 'D'
            },
            mySelf: false,
            names: [
                {
                    key: 5,
                    code: 'BJB',
                    displayName: 'Branch, Bruce John',
                    type: 'AdhocResponsibleName'
                },
                {
                    key: 2,
                    code: 2,
                    displayName: 'Mary',
                    type: 'CriticalList'
                }
            ],
            otherNames: [
            ],
            nameType: {
                key: 'D',
                code: 'D',
                value: 'Debtor'
            },
            emailToRecipients: 1,
            dueDate: undefined,
            event: null,
            responsibleNameForMaintain: {
                type: 'AdhocResponsibleName',
                key: 5,
                code: 'BJB',
                displayName: 'Branch, Bruce John'
            },
            message: 'one hour',
            daysLead: 1,
            dailyFrequency: 1,
            monthsLead: null,
            monthlyFrequency: null,
            isRecurring: 1,
            repeatEvery: 1,
            importanceLevel: 9,
            emailSubjectLine: 'asdasda',
            deleteOn: undefined,
            endOn: undefined,
            finalise: null,
            reason: null,
            relationship: {
                key: 'REN',
                code: 'REN',
                value: 'Send Renewals To'
            },
            staff: true,
            signatory: true,
            criticalList: true
        };
        expect(component.formData).toEqual(result);
    });
    it('should call edit with no reminder details', () => {
        component.adhocDateDetails.daysLead = null;
        component.adhocDateDetails.dailyFrequency = null;
        component.adhocDateDetails.monthsLead = null;
        component.mode = adhocTypeMode.maintain;
        component.ngOnInit();
        expect(component.noReminder).toEqual(true);
        expect(component.formData.sendreminder).toEqual({
            value: 0,
            type: 'D'
        });
        expect(component.formData.names.length).toEqual(1);
        expect(component.formData.mySelf).toEqual(false);
        expect(component.formData.staff).toEqual(false);
        expect(component.formData.signatory).toEqual(false);
        expect(component.formData.criticalList).toEqual(false);
    });
    it('should call edit with  reminder details on name details', () => {
        component.adhocDateDetails.type = 'name';
        component.mode = adhocTypeMode.maintain;
        component.ngOnInit();
        expect(component.formData.names.length).toEqual(1);
        expect(component.formData.mySelf).toEqual(false);
        expect(component.formData.staff).toEqual(false);
        expect(component.formData.signatory).toEqual(false);
        expect(component.formData.criticalList).toEqual(false);
        expect(component.isRecuring).toEqual(false);
        expect(component.formData.repeatEvery).toEqual(1);
        expect(component.formData.names.length).toEqual(1);
    });
    it('should call canDelete', () => {
        component.mode = adhocTypeMode.maintain;
        component.viewData.canDeleteAdHoc = true;
        expect(component.canDelete()).toEqual(true);
        component.viewData.canDeleteAdHoc = false;
        expect(component.canDelete()).toEqual(false);
    });

    it('should call onDelete', () => {
        component.onDelete();
        expect(ipxNotificationService.openConfirmationModal).toHaveBeenCalled();
    });

    it('should call deleteAdHoc', done => {
        const response = { status: 'success' };
        adHocDateService.delete.mockReturnValue(of(response));
        component.deleteAdHoc();
        adHocDateService.delete(45).subscribe((result: any) => {
            expect(result).toEqual(response);
            expect(notificationService.success).toHaveBeenCalled();
            expect(modalRef.hide).toHaveBeenCalled();
            expect(taskPlannerService.onActionComplete$.next).toHaveBeenCalled();
            done();
        });
    });
});
