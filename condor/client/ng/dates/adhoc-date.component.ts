import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, Subject, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, take, takeLast, takeWhile } from 'rxjs/operators';
import { ReminderActionStatus } from 'search/task-planner/task-planner.data';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { AdhocReminder } from './adhoc-date.model';
import { AdhocDateService, adhocType, adhocTypeMode } from './adhoc-date.service';

@Component({
    selector: 'adhoc-date',
    templateUrl: './adhoc-date.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class AdHocDateComponent implements OnInit, OnDestroy, AfterViewInit {
    viewData: any;
    caseEventDetails: any;
    adhocDateDetails: any;
    resolveReasons: Array<any> = [];
    mode: string;
    taskPlannerRowKey: string;
    canFinaliseAdhoc: boolean;
    defaultAdhocInfo: any;
    fromEventNotes: boolean;
    formData: any;
    isAddAnotherChecked: boolean;
    isLoading = false;
    saveCall = false;
    today = new Date();
    onClose$ = new Subject();
    changeRecipientAction: BehaviorSubject<boolean>;
    createCopyRecipientAction: BehaviorSubject<boolean>;
    cancelRecipientAction: BehaviorSubject<boolean>;
    onDueDateChanged: () => void;
    onDeleteOnChanged: (event: any) => void;
    onEndOnChanged: (event: any) => void;
    onEventChanged: (event: any) => void;
    onAdhocTypeChanged: (event: any) => void;
    reminderChanged: (event: any) => void;
    toggleRecuring: (event: any) => void;
    toggleMyself: (event: any) => void;
    toggleStaff: (event: any) => void;
    toggleSignatory: (event: any) => void;
    toggleCriticalList: (event: any) => void;

    periodTypes: any;
    @ViewChild('adhocForm', { static: true }) adhocForm: NgForm;
    noReminder: boolean;
    isRecuring: boolean;
    employeeSignatory = [];
    nameTypeRelationShip = [];
    adhocResposiblity: any;
    adhocReminderDetails = new AdhocReminder();
    adhocGenerateNameList: Array<AdhocReminder> = [];
    isAdhocTypeCase = false;
    modalRef: BsModalRef;
    adhocType = adhocType;
    isEmailDisabled = false;
    deleteSubscription: Subscription;
    adhocTypeMode = adhocTypeMode;
    isCreateCopy = false;

    constructor(private readonly bsModalRef: BsModalRef,
        private readonly adhocDateService: AdhocDateService,
        private readonly notificationService: NotificationService,
        private readonly dateHelper: DateHelper,
        private readonly cdref: ChangeDetectorRef,
        private readonly taskPlannerService: TaskPlannerService,
        private readonly localSettings: LocalSettings,
        private readonly ipxNotificationService: IpxNotificationService) {
        this.changeRecipientAction = new BehaviorSubject<boolean>(false);
        this.createCopyRecipientAction = new BehaviorSubject<boolean>(false);
        this.cancelRecipientAction = new BehaviorSubject<boolean>(false);
    }
    ngAfterViewInit(): void {
        if (this.mode === adhocTypeMode.maintain) {
            setTimeout(() => {
                this.adhocForm.form.markAsUntouched();
                this.adhocForm.form.markAsPristine();
                this.adhocForm.controls.endOn.setErrors(null);
                this.adhocForm.controls.dueDate.setErrors(null);
                this.adhocForm.controls.deleteOn.setErrors(null);
            });
        }
        setTimeout(() => {
            this.adhocForm.controls.adHocResponsible.valueChanges.pipe(debounceTime(500), distinctUntilChanged()).subscribe((value: any) => {
                if (this.changeRecipientAction.getValue()) {
                    this.changeRecipientAction.next(false);

                    return;
                }
                if (this.createCopyRecipientAction.getValue()) {
                    this.createCopyRecipientAction.next(false);

                    return;
                }
                if (this.cancelRecipientAction.getValue()) {
                    this.cancelRecipientAction.next(false);

                    return;
                }

                if (!!value && value.key) {
                    this.adHocResponsibleChange(value);
                }
            });
            this.adhocForm.controls.alertTemplate.valueChanges.pipe(debounceTime(500), distinctUntilChanged()).subscribe((value: any) => {
                if (!!value && value.code) {
                    this.onTemplateChanged(value);
                }
            });
        });
    }

    ngOnInit(): void {
        this.periodTypes = this.adhocDateService.getPeriodTypes();
        this.initFormData();
        this.onDueDateChanged = () => {
            this.adhocForm.controls.event.setErrors(null);
            if (this.formData.dueDate) {
                this.formData.event = null;
            }
            if (this.formData.adhocTemplate && this.formData.dueDate) {
                this.setEndOnDeleteOn();
            }
        };
        this.onDeleteOnChanged = (event: any) => {
            if (event && this.formData.dueDate && (this.formData.dueDate > event)) {
                this.adhocForm.controls.deleteOn.setErrors({ 'adHocDate.validations.endOnDueDateMessage': true });

                return;
            }

        };
        this.onEventChanged = (event: any) => {
            if (!event) {

                return;
            }
            this.adhocForm.controls.dueDate.setErrors(null);
        };
        this.onAdhocTypeChanged = (event: any) => {
            this.adhocForm.controls.dueDate.setErrors(null);
            this.adhocForm.controls.event.setErrors(null);
            if (this.formData.adhocType === 'name' || this.formData.adhocType === 'general') {
                this.formData.event = null;
                this.clearReminderControls();
                this.isAdhocTypeCase = true;
            } else {
                if (this.formData.adhocTemplate) {
                    this.applyAdhocTemplate();
                } else {
                    this.setStaffSignatoryCritical();
                }
                this.isAdhocTypeCase = false;
            }
        };
        this.onEndOnChanged = (event: any) => {
            if (event && this.formData.dueDate && (this.formData.dueDate > event)) {
                this.adhocForm.controls.endOn.setErrors({ 'adHocDate.validations.endOnDueDateMessage': true });

                return;
            }

            if (event && this.formData.deleteOn && (this.formData.deleteOn < event)) {
                this.adhocForm.controls.endOn.setErrors({ 'adHocDate.validations.endOnAutomaticDeleteMessage': true });

                return;
            }
        };

        this.reminderChanged = (event: any) => {
            this.noReminder = event;
            if (this.noReminder) {
                this.clearReminderControls();
                this.clearRecuringControls();
            } else {
                if (this.formData.adhocType === 'case') {
                    this.isRecuring = true;
                    this.adhocForm.controls.mySelf.setValue(1);
                    if (this.formData.adhocTemplate) {
                        this.applyAdhocTemplate();
                    } else {
                        this.setStaffSignatoryCritical();
                    }
                }
            }
        };

        this.toggleRecuring = (event: any) => {
            this.isRecuring = !event;
            if (!event) {
                this.clearRecuringControls();
            } else {
                if (this.formData.sendreminder && (this.formData.sendreminder.value !== 0 && Number(this.formData.sendreminder.value))) {
                    this.adhocForm.controls.repeatEvery.setValue(+this.formData.sendreminder.value);
                    this.formData.repeatEvery = +this.formData.sendreminder.value;
                }
            }
        };

        this.toggleMyself = (event: any) => {
            if (this.viewData.loggedInUser) {
                const exists = this.checkKeyExistInNamesPicklist(this.viewData.loggedInUser.key);
                if (event) {
                    if (!exists) {
                        this.formData.names = this.formData.names.filter(x => x.key !== null);
                        this.formData.names.push({
                            key: this.viewData.loggedInUser.key,
                            code: this.viewData.loggedInUser.code,
                            displayName: this.viewData.loggedInUser.displayName,
                            type: adhocType.myself
                        });
                    }
                } else {
                    if (exists) {
                        const itemToDelete = this.formData.names.filter(x => x.key === this.viewData.loggedInUser.key);
                        if (itemToDelete.length && this.isNameAvailbaleForOtherCheckBox(adhocType.myself, this.viewData.loggedInUser.key)) {
                            this.formData.names = this.formData.names.filter(x => x.key !== itemToDelete[0].key);
                        }
                    }
                }
            }
        };

        this.toggleStaff = (event: any) => {
            this.localSettings.keys.taskPlanner.showStaff.setLocal(event);
            const staffDetails = _.first(this.employeeSignatory.filter(x => x.type === adhocType.staff));
            if (this.employeeSignatory.length && staffDetails) {
                const exists = this.checkKeyExistInNamesPicklist(staffDetails.key);
                if (event) {
                    if (!exists) {
                        this.formData.names = this.formData.names.filter(x => x.key !== null);
                        this.formData.names.push(staffDetails);
                    }
                } else {
                    if (exists) {
                        const itemToDelete = this.formData.names.filter(x => x.key === staffDetails.key);
                        if (itemToDelete.length && this.isNameAvailbaleForOtherCheckBox(adhocType.staff, staffDetails.key)) {
                            this.formData.names = this.formData.names.filter(x => x.key !== itemToDelete[0].key);
                        }
                    }
                }
            }

        };

        this.toggleSignatory = (event: any) => {
            this.localSettings.keys.taskPlanner.showSignatory.setLocal(event);
            const signatoryDetails = _.first(this.employeeSignatory.filter(x => x.type === adhocType.signatory));
            if (this.employeeSignatory.length && signatoryDetails) {
                const exists = this.checkKeyExistInNamesPicklist(signatoryDetails.key);
                if (event) {
                    if (!exists) {
                        this.formData.names = this.formData.names.filter(x => x.key !== null);
                        this.formData.names.push(signatoryDetails);
                    }
                } else {
                    if (exists) {
                        const itemToDelete = this.formData.names.filter(x => x.key === signatoryDetails.key);
                        if (itemToDelete.length && this.isNameAvailbaleForOtherCheckBox(adhocType.signatory, signatoryDetails.key)) {
                            this.formData.names = this.formData.names.filter(x => x.key !== itemToDelete[0].key);
                        }
                    }
                }
            }
        };

        this.toggleCriticalList = (event: any) => {
            this.localSettings.keys.taskPlanner.showCriticalList.setLocal(event);
            if (this.viewData.criticalUser) {
                const exists = this.checkKeyExistInNamesPicklist(this.viewData.criticalUser.key);
                if (event) {
                    if (!exists) {
                        this.formData.names = this.formData.names.filter(x => x.key !== null);
                        this.formData.names.push({
                            key: this.viewData.criticalUser.key,
                            code: this.viewData.criticalUser.code,
                            displayName: this.viewData.criticalUser.displayName,
                            type: adhocType.criticalList
                        });
                    }
                } else {
                    if (exists) {
                        const itemToDelete = this.formData.names.filter(x => x.key === this.viewData.criticalUser.key);
                        if (itemToDelete.length && this.isNameAvailbaleForOtherCheckBox(adhocType.criticalList, this.viewData.criticalUser.key)) {
                            this.formData.names = this.formData.names.filter(x => x.key !== itemToDelete[0].key);
                        }
                    }
                }
            }
        };
    }

    ngOnDestroy(): void {
        if (!!this.deleteSubscription) {
            this.deleteSubscription.unsubscribe();
        }
    }

    isNameAvailbaleForOtherCheckBox(control: any, key: any): boolean {
        let result = true;
        const staff = _.first(this.employeeSignatory.filter(x => x.key === key && x.type === adhocType.staff));
        const signatory = _.first(this.employeeSignatory.filter(x => x.key === key && x.type === adhocType.signatory));
        result = this.checkForOtherCheckbox(control, key, staff, signatory);

        return result;
    }

    checkForOtherCheckbox(control: any, key: any, staff: any, signatory: any): boolean {
        switch (control) {
            case adhocType.myself: {
                return !this.checkForMyself(key, staff, signatory);
            }
            case adhocType.staff: {
                return !this.checkForStaff(key, signatory);
            }
            case adhocType.signatory: {
                return !this.checkForSignatory(key, staff);
            }
            case adhocType.criticalList: {
                return !this.checkForCriticallist(key, staff, signatory);
            }
            default: {
                return true;
            }
        }
    }

    canDelete = () => {
        return this.mode === adhocTypeMode.maintain && this.viewData.canDeleteAdHoc;
    };

    onDelete = () => {
        const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('adHocDate.tooltipConfirmDelete');

        notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
            .subscribe(() => {
                this.deleteAdHoc();
            });
    };

    deleteAdHoc = () => {
        this.deleteSubscription = this.adhocDateService.delete(this.adhocDateDetails.alertId)
            .subscribe((r: any) => {
                if (r.status === ReminderActionStatus.Success) {
                    this.notificationService.success();
                }
                this.bsModalRef.hide();
                this.taskPlannerService.onActionComplete$.next({ reloadGrid: true, unprocessedRowKeys: [] });
            });
    };

    checkForMyself(key: any, staff: any, signatory: any): boolean {
        return (this.formData.staff && staff) || (this.formData.signatory && signatory) || (this.formData.criticalList && this.viewData.criticalUser.key === key) || (this.formData.responsibleName && this.formData.responsibleName.key === key);
    }

    checkForStaff(key: any, signatory: any): boolean {
        return (this.formData.mySelf && this.viewData.loggedInUser.key === key) || (this.formData.signatory && signatory) || (this.formData.criticalList && this.viewData.criticalUser.key === key);
    }

    checkForSignatory(key: any, staff: any): boolean {
        return (this.formData.mySelf && this.viewData.loggedInUser.key === key) || (this.formData.staff && staff) || (this.formData.criticalList && this.viewData.criticalUser.key === key);
    }

    checkForCriticallist(key: any, staff: any, signatory: any): boolean {
        return (this.formData.mySelf && this.viewData.loggedInUser.key === key) || (this.formData.staff && staff) || (this.formData.signatory && signatory);
    }

    adHocResponsibleChange(event: any): void {
        if (this.mode === adhocTypeMode.maintain) {
            const modal = this.ipxNotificationService.openAdHocDateMaintenanceModal();
            modal.content.createCopy$.pipe(take(1)).subscribe(() => {
                this.createCopyRecipientAction.next(true);
                this.formData.responsibleName = this.adhocResposiblity;
                this.cdref.detectChanges();
                this.isCreateCopy = true;
            });
            modal.content.cancelled$.pipe(take(1)).subscribe(() => {
                this.cancelRecipientAction.next(true);
                this.adhocForm.controls.adHocResponsible.setValue(this.formData.responsibleNameForMaintain);
                this.bindAdhocResponsblity(this.formData.responsibleNameForMaintain);
            });
            modal.content.confirmed$.pipe(take(1)).subscribe(() => {
                this.changeRecipientAction.next(true);
                this.formData.responsibleName = this.adhocResposiblity;
                this.cdref.detectChanges();
            });
        }
        this.bindAdhocResponsblity(event);
    }

    bindAdhocResponsblity(event: any): void {
        this.formData.names = this.formData.names.filter(x => x.type !== adhocType.adhocResponsibleName);
        const exists = this.checkKeyExistInNamesPicklist(event.key);
        const value = {
            key: event.key,
            code: event.code,
            displayName: event.displayName,
            type: adhocType.adhocResponsibleName
        };
        if (!exists && !this.noReminder) {
            this.formData.names.push(value);
            if (!this.formData.mySelf) {
                this.formData.names = this.formData.names.filter(x => x.key !== this.viewData.loggedInUser.key);
            }
            this.bindStaffSignatoryWithNamesPicklist();
        }
        this.adhocResposiblity = value;
    }

    caseRefChange(event: any): void {
        this.formData.names = this.formData.names.filter(x => x.type !== adhocType.relationShip);
        if (!this.formData.adhocTemplate) {
            this.adhocForm.controls.nameType.setValue(null);
            this.adhocForm.controls.relationship.setValue(null);
        }
        if (event.key) {
            this.callStaffSignatory(event.key);
        }
    }

    callStaffSignatory(key: any): void {
        this.adhocDateService.nameDetails(key).subscribe(result => {
            this.employeeSignatory = [];
            this.employeeSignatory = result;
            if (!this.noReminder) {
                this.bindStaffSignatoryWithNamesPicklist();
            }
        });
    }

    bindStaffSignatoryWithNamesPicklist(): void {
        const existsStaff = this.checkKeyExistInNamesPicklist(this.viewData.loggedInUser.key);
        if (!existsStaff && this.formData.mySelf) {
            this.formData.names.push(this.viewData.loggedInUser);
        }
        if (this.employeeSignatory.length > 0) {
            this.formData.names = this.formData.names.filter(x => x.type !== adhocType.staff && x.type !== adhocType.signatory &&
                x.type !== adhocType.relationShip);

            _.each(this.employeeSignatory, (item: any) => {
                const exists = this.checkKeyExistInNamesPicklist(item.key);
                if (!exists) {
                    if ((item.type === adhocType.staff && this.formData.staff) || (item.type === adhocType.signatory && this.formData.signatory)) {
                        this.formData.names.push(item);
                    }
                }
            });
        }
        this.cdref.markForCheck();
    }

    nameTypeChange(event: any): void {
        this.formData.names = this.formData.names.filter(x => x.type !== adhocType.relationShip);
        this.adhocForm.controls.relationship.setValue(null);
    }

    nameTypeRelationship(event: any): void {
        this.formData.names = this.formData.names.filter(x => x.type !== adhocType.relationShip);
        if (event.key) {
            if (this.formData.reference.case && this.formData.nameType) {
                this.adhocDateService.nameTypeRelationShip(this.formData.reference.case.key, this.formData.nameType.code, event.code).subscribe(result => {
                    this.nameTypeRelationShip = [];
                    this.nameTypeRelationShip = result;
                    this.formData.names = this.formData.names.filter(x => x.type !== adhocType.relationShip);
                    if (this.nameTypeRelationShip.length > 0) {
                        _.each(this.nameTypeRelationShip, (item: any) => {
                            const exists = this.checkKeyExistInNamesPicklist(item.key);
                            if (!exists) {
                                this.formData.names.push(item);
                            }
                        });
                    }
                    this.cdref.markForCheck();
                });
            }
        }
    }

    checkKeyExistInNamesPicklist(key: any): boolean {
        return _.any(this.formData.names, (itemnames: any) => {
            return itemnames.key === key;
        });
    }

    initFormData = () => {
        this.noReminder = false;
        this.isRecuring = true;
        if (this.mode === adhocTypeMode.maintain) {
            this.initFormDefaults();
            this.initFromDetails();
        } else {
            this.initDefaults();
        }
    };

    initFromDetails = () => {
        this.formData.mySelf = false;
        this.formData.names = [];
        this.formData.adhocType = this.adhocDateDetails.type;
        this.formData.reference = this.adhocDateDetails.reference;
        if (this.formData.reference.case) {
            this.callStaffSignatory(this.formData.reference.case.key);
        }
        this.formData.dueDate = this.adhocDateDetails.dueDate ? this.dateHelper.convertForDatePicker(this.adhocDateDetails.dueDate) : null;
        this.formData.event = this.adhocDateDetails.event;
        this.adhocResposiblity = this.adhocDateDetails.adhocResponsibleName;
        this.formData.responsibleName = this.adhocResposiblity;
        this.formData.responsibleNameForMaintain = this.adhocResposiblity;
        this.formData.message = this.adhocDateDetails.message;
        this.formData.daysLead = this.adhocDateDetails.daysLead;
        this.formData.dailyFrequency = this.adhocDateDetails.dailyFrequency;
        this.formData.monthsLead = this.adhocDateDetails.monthsLead;
        this.formData.monthlyFrequency = this.adhocDateDetails.monthlyFrequency;
        if (!this.formData.daysLead && !this.formData.dailyFrequency && !this.formData.monthsLead) {
            this.noReminder = true;
            this.formData.sendreminder = {
                value: 0,
                type: 'D'
            };
        }
        this.formData.noReminder = this.noReminder;
        if (!this.noReminder) {
            let value = this.adhocDateDetails.daysLead;
            let type = 'D';
            let frequency = this.adhocDateDetails.dailyFrequency;
            if (this.adhocDateDetails.dailyFrequency && this.adhocDateDetails.monthlyFrequency) {
                value = this.adhocDateDetails.daysLead;
                type = 'D';
                frequency = this.adhocDateDetails.dailyFrequency;
            } else if (this.adhocDateDetails.monthlyFrequency) {
                value = this.adhocDateDetails.monthsLead;
                type = 'M';
                frequency = this.adhocDateDetails.monthlyFrequency;
            }
            this.formData.sendreminder = {
                value,
                type
            };
            this.formData.isRecurring = this.adhocDateDetails.dailyFrequency || this.adhocDateDetails.monthlyFrequency;
            this.isRecuring = !this.formData.isRecurring;
            this.formData.repeatEvery = frequency;
        }
        this.formData.importanceLevel = this.adhocDateDetails.importanceLevel;
        this.formData.emailToRecipients = this.adhocDateDetails.sendElectronically;
        this.isEmailDisabled = !this.formData.emailToRecipients;
        this.formData.emailSubjectLine = this.adhocDateDetails.emailSubject;
        this.formData.deleteOn = this.adhocDateDetails.deleteOn ? this.dateHelper.convertForDatePicker(this.adhocDateDetails.deleteOn) : null;
        this.formData.endOn = this.adhocDateDetails.endOn ? this.dateHelper.convertForDatePicker(this.adhocDateDetails.endOn) : null;
        this.formData.finalise = this.adhocDateDetails.dateOccurred ? this.dateHelper.convertForDatePicker(this.adhocDateDetails.dateOccurred) : null;
        this.formData.reason = this.adhocDateDetails.resolveReason;
        if (!this.noReminder && this.formData.adhocType === 'case') {
            this.formData.nameType = this.adhocDateDetails.nameTypeValue;
            this.formData.relationship = this.adhocDateDetails.relationshipValue;
            this.setStaffSignatoryCriticalForMaintain();
        } else {
            this.formData.staff = false;
            this.formData.signatory = false;
            this.formData.criticalList = false;
            this.isRecuring = false;
            this.isAdhocTypeCase = true;
            this.criticalAdhocResponsible();
        }
    };

    initDefaults = () => {
        this.initFormDefaults();
        if (this.caseEventDetails) {
            this.formData.reference = {
                case: this.caseEventDetails.case
            };
        }
        if (this.defaultAdhocInfo) {
            this.formData.dueDate = this.dateHelper.convertForDatePicker(this.defaultAdhocInfo.dueDate);
            this.formData.message = this.defaultAdhocInfo.message;
            this.formData.reference.case = this.defaultAdhocInfo.case;
        }
        this.setStaffSignatoryCritical(this.caseEventDetails ? this.caseEventDetails.case.key : null);
        if (this.viewData.defaultAdHocImportance) {
            this.formData.importanceLevel = _.first(_.filter(this.viewData.importanceLevelOptions, (il: any) => {
                return il.code === this.viewData.defaultAdHocImportance;
            })).code;
        }
        this.isEmailDisabled = !this.formData.emailToRecipients;
    };

    initFormDefaults(): void {
        this.formData = {
            adhocType: 'case',
            responsibleName: {
                key: this.viewData.loggedInUser.key,
                code: this.viewData.loggedInUser.code,
                displayName: this.viewData.loggedInUser.displayName,
                type: this.viewData.loggedInUser.type
            },
            reference: {},
            noReminder: false,
            sendreminder: { value: 0, type: 'D' },
            mySelf: true,
            names: [this.viewData.loggedInUser],
            otherNames: [],
            nameType: null,
            emailToRecipients: this.localSettings.keys.taskPlanner.showEmailReminder.getLocal
        };
    }

    setStaffSignatoryCritical(key?: any, isFromTemplate = false): void {
        this.formData.staff = isFromTemplate ? this.formData.adhocTemplate.employeeFlag : this.localSettings.keys.taskPlanner.showStaff.getLocal;
        this.formData.signatory = isFromTemplate ? this.formData.adhocTemplate.signatoryFlag : this.localSettings.keys.taskPlanner.showSignatory.getLocal;
        this.formData.criticalList = isFromTemplate ? this.formData.adhocTemplate.criticalFlag : this.localSettings.keys.taskPlanner.showCriticalList.getLocal;
        this.formData.names = this.formData.names.filter(x => x.key !== null);
        this.criticalAdhocResponsible();
        if ((this.formData.staff || this.formData.signatory) && key) {
            this.callStaffSignatory(key);
        } else {
            this.bindStaffSignatoryWithNamesPicklist();
        }
        if (isFromTemplate) {
            if (this.formData.relationship) {
                this.nameTypeRelationship(this.formData.relationship);
            }
        } else {
            this.formData.emailToRecipients = this.localSettings.keys.taskPlanner.showEmailReminder.getLocal;
            this.isEmailDisabled = !this.formData.emailToRecipients;
        }
        this.formData.names = this.formData.names.filter(x => x.type !== adhocType.relationShip);
    }

    setStaffSignatoryCriticalForMaintain(): void {
        this.formData.staff = this.adhocDateDetails.employeeFlag;
        this.formData.signatory = this.adhocDateDetails.signatoryFlag;
        this.formData.criticalList = this.adhocDateDetails.criticalFlag;
        this.criticalAdhocResponsible();
        if ((this.formData.staff || this.formData.signatory) && this.formData.adhocType === 'case' && this.formData.reference.case) {
            this.callStaffSignatory(this.formData.reference.case.key);
        } else {
            this.bindStaffSignatoryWithNamesPicklist();
        }

        if (this.formData.relationship) {
            this.nameTypeRelationship(this.formData.relationship);
        }
        this.formData.names = this.formData.names.filter(x => x.type !== adhocType.relationShip);
    }

    criticalAdhocResponsible(): void {
        if (this.adhocResposiblity) {
            const existsRespons = this.checkKeyExistInNamesPicklist(this.adhocResposiblity.key);
            if (!existsRespons) {
                this.formData.names.push({
                    key: this.adhocResposiblity.key,
                    code: this.adhocResposiblity.code,
                    displayName: this.adhocResposiblity.displayName,
                    type: adhocType.adhocResponsibleName
                });
            }
        }
        if (this.formData.criticalList) {
            const exists = this.checkKeyExistInNamesPicklist(this.viewData.criticalUser.key);
            if (!exists) {
                this.formData.names.push({
                    key: this.viewData.criticalUser.key,
                    code: this.viewData.criticalUser.code,
                    displayName: this.viewData.criticalUser.displayName,
                    type: adhocType.criticalList
                });
            }
        }
    }

    enableRecurringControls(): any {
        if (this.noReminder) {
            return true;
        }

        return this.isRecuring;
    }

    enableEmailSubjectLine(): any {
        if (this.noReminder) {
            return true;
        }

        return this.isEmailDisabled;
    }

    toggleEmailSubjectLine = (event: any) => {
        this.localSettings.keys.taskPlanner.showEmailReminder.setLocal(event);
        this.isEmailDisabled = !event;
        if (!event) {
            if (this.adhocForm.controls.emailSubjectLine) {
                this.adhocForm.controls.emailSubjectLine.setValue('');
            }
        }
    };

    clearRecuringControls(): void {
        this.formData.sendreminder = { value: 0, type: 'D' };
        this.formData.isRecurring = false;
        this.formData.repeatEvery = null;
        this.formData.endOn = null;
        this.isRecuring = true;
    }

    clearReminderControls(): void {
        this.formData.staff = 0;
        this.formData.signatory = 0;
        this.formData.criticalList = 0;
        this.formData.nameType = null;
        this.formData.relationship = null;
        if (this.noReminder) {
            this.formData.names = [];
            if (this.mode !== adhocTypeMode.maintain) {
                this.formData.otherNames = [];
            }
            this.formData.mySelf = 0;
        }
        if (this.formData.adhocType === 'case') {
            this.formData.emailSubjectLine = null;
            this.formData.emailToRecipients = false;
            this.isEmailDisabled = true;
        } else {
            this.formData.names = (this.viewData.loggedInUser.key === (this.formData.responsibleName && this.formData.responsibleName.key) && this.formData.mySelf) ?
                this.formData.names.filter(x => x.type === adhocType.myself) : (this.viewData.loggedInUser.key === (this.formData.responsibleName && this.formData.responsibleName.key) && !this.formData.mySelf) ?
                    this.formData.names = this.formData.names.filter(x => x.type === adhocType.adhocResponsibleName) : this.formData.names.filter(x => x.type === adhocType.adhocResponsibleName || x.type === adhocType.myself);
        }
    }

    onTemplateChanged = (event: any) => {
        const notificationRef = this.ipxNotificationService.openConfirmationModal('adHocDate.adhocTemplate.title', 'adHocDate.adhocTemplate.message', 'adHocDate.adhocTemplate.proceed', 'adHocDate.adhocTemplate.cancel');
        notificationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
            this.applyAdhocTemplate();
        });
        notificationRef.content.cancelled$.pipe(take(1)).subscribe(() => {
            this.adhocForm.controls.alertTemplate.setValue(null);
        });
    };

    applyAdhocTemplate = () => {
        if (this.formData.adhocTemplate) {
            this.formData.names = this.formData.names.filter(x => x.type !== adhocType.staff && x.type !== adhocType.signatory && x.type !== adhocType.criticalList);
            if (!this.formData.mySelf) {
                this.formData.names = this.formData.names.filter(x => x.type !== adhocType.myself);
            }
            this.adhocResposiblity = this.formData.adhocTemplate.adhocResponsibleName;
            this.formData.responsibleName = this.adhocResposiblity;
            this.formData.message = this.formData.adhocTemplate.message;
            this.formData.daysLead = this.formData.adhocTemplate.daysLead;
            this.formData.dailyFrequency = this.formData.adhocTemplate.dailyFrequency;
            this.formData.monthsLead = this.formData.adhocTemplate.monthsLead;
            this.formData.monthlyFrequency = this.formData.adhocTemplate.monthlyFrequency;
            if (!this.noReminder) {
                let value = this.formData.adhocTemplate.daysLead;
                let type = 'D';
                let frequency = this.formData.adhocTemplate.dailyFrequency;
                if (this.formData.adhocTemplate.dailyFrequency && this.formData.adhocTemplate.monthlyFrequency) {
                    value = this.formData.daysLead;
                    type = 'D';
                    frequency = this.formData.adhocTemplate.dailyFrequency;
                } else if (this.formData.adhocTemplate.monthlyFrequency) {
                    value = this.formData.monthsLead;
                    type = 'M';
                    frequency = this.formData.adhocTemplate.monthlyFrequency;
                }
                this.adhocForm.controls.sendreminder.setValue({ value, type });
                this.formData.isRecurring = this.formData.adhocTemplate.dailyFrequency || this.formData.adhocTemplate.monthlyFrequency;
                this.isRecuring = !this.formData.isRecurring;
                this.formData.repeatEvery = frequency;
            }
            this.formData.importanceLevel = this.formData.adhocTemplate.importanceLevel ? this.formData.adhocTemplate.importanceLevel : this.viewData.defaultAdHocImportance;
            this.formData.emailToRecipients = this.formData.adhocTemplate.sendElectronically;
            this.isEmailDisabled = !this.formData.emailToRecipients;
            this.formData.emailSubjectLine = this.formData.adhocTemplate.emailSubject;
            this.setEndOnDeleteOn();
            this.setPicklistValueFromTemplate();
        }
    };

    setPicklistValueFromTemplate(): void {
        if (!this.noReminder && this.formData.adhocType === 'case') {
            this.formData.nameType = this.formData.adhocTemplate.nameTypeValue;
            this.formData.relationship = this.formData.adhocTemplate.relationshipValue;
            this.setStaffSignatoryCritical(null, true);
        }
    }

    setEndOnDeleteOn(): void {
        const dueDate = this.formData.dueDate;
        this.formData.endOn = (dueDate && this.formData.adhocTemplate.stopAlert) ? this.dateHelper.addDays(dueDate, this.formData.adhocTemplate.stopAlert) : null;
        if (!this.noReminder) {
            this.formData.deleteOn = (dueDate && this.formData.adhocTemplate.deleteAlert) ? this.dateHelper.addDays(dueDate, this.formData.adhocTemplate.deleteAlert) : null;
        }
    }

    formValid = () => {
        return this.adhocForm.dirty && this.adhocForm.valid;
    };

    validate = () => {
        if (this.formData.adhocType === 'case' && !this.formData.dueDate && !this.formData.event) {
            this.adhocForm.controls.dueDate.setErrors({ 'adHocDate.validations.eitherDueOrEvent': true });
            this.adhocForm.controls.event.markAsDirty();
            this.adhocForm.controls.event.setErrors({ 'adHocDate.validations.eitherDueOrEvent': true });

            return false;
        }

        if (this.formData.adhocType === 'name' && !this.formData.dueDate) {
            this.adhocForm.controls.dueDate.setErrors({ 'adHocDate.validations.dueDateRequired': true });

            return false;
        }

        if (this.formData.adhocType === 'general' && !this.formData.dueDate) {
            this.adhocForm.controls.dueDate.setErrors({ 'adHocDate.validations.dueDateRequired': true });

            return false;
        }

        return true;
    };

    onSave = () => {
        if (!this.validate() || this.isLoading) {
            return;
        }
        this.isLoading = true;
        this.saveDetailsAdhoc();
        if (this.mode === this.adhocTypeMode.maintain && !this.isCreateCopy) {
            this.adhocReminderDetails.taskPlannerRowKey = this.taskPlannerRowKey;
            this.adhocDateService.maintainAdhocDate(this.adhocDateDetails.alertId, this.adhocReminderDetails)
                .subscribe((r: any) => {
                    this.saveCall = true;
                    this.isLoading = false;
                    if (r.status === ReminderActionStatus.Success) {
                        this.notificationService.success();
                    }
                    this.bsModalRef.hide();
                    this.onClose$.next(true);
                    this.taskPlannerService.onActionComplete$.next({ reloadGrid: true, unprocessedRowKeys: [] });
                });
        } else {
            this.adhocDateService.saveAdhocDate(this.adhocGenerateNameList).subscribe(r => {
                this.saveCall = true;
                this.isLoading = false;
                if (r.status === ReminderActionStatus.Success) {
                    this.notificationService.success();
                }
                if (!this.isAddAnotherChecked) {
                    this.bsModalRef.hide();
                    this.onClose$.next(true);
                    if (!this.fromEventNotes) {
                        this.taskPlannerService.onActionComplete$.next({ reloadGrid: true, unprocessedRowKeys: [] });
                    }
                } else {
                    this.initFormData();
                    this.adhocForm.form.markAsPristine();
                }
            }, error => {
                this.isLoading = false;
                this.cdref.markForCheck();
            });
        }
        this.cdref.markForCheck();
    };

    saveDetailsAdhoc = () => {
        this.adhocGenerateNameList = [];
        this.adhocReminderDetails.employeeNo = this.formData.responsibleName.key;
        this.adhocReminderDetails.caseId = this.formData.adhocType === 'case' ? this.formData.reference.case.key : null;
        this.adhocReminderDetails.nameNo = this.formData.adhocType === 'name' ? this.formData.reference.name.key : null;
        this.adhocReminderDetails.reference = this.formData.adhocType === 'general' ? this.formData.reference.general : null;
        this.adhocReminderDetails.dueDate = this.formData.dueDate ? this.dateHelper.toLocal(this.formData.dueDate) : null;
        this.adhocReminderDetails.alertMessage = this.formData.message;
        this.adhocReminderDetails.eventNo = this.formData.event ? this.formData.event.key : null;
        this.adhocReminderDetails.importanceLevel = this.formData.importanceLevel;
        this.adhocReminderDetails.deleteOn = this.formData.deleteOn ? this.dateHelper.toLocal(this.formData.deleteOn) : null;
        this.adhocReminderDetails.stopReminderDate = this.formData.endOn ? this.dateHelper.toLocal(this.formData.endOn) : null;
        this.adhocReminderDetails.dateOccurred = this.formData.finalise ? this.dateHelper.toLocal(this.formData.finalise) : null;
        this.adhocReminderDetails.userCode = this.formData.reason ? this.formData.reason : null;
        this.adhocReminderDetails.taskPlannerRowKey = this.taskPlannerRowKey;
        this.setReminderModel();
        if (this.mode !== adhocTypeMode.maintain || this.isCreateCopy) {
            this.adhocGenerateNameList.push(this.adhocReminderDetails);
            this.maintainAdditionalNames();
        }
    };

    setReminderModel(): void {
        this.adhocReminderDetails.isNoReminder = this.formData.noReminder;
        this.adhocReminderDetails.daysLead = this.formData.noReminder ? null : this.formData.sendreminder && this.formData.sendreminder.type === 'D' ? this.formData.sendreminder.value : null;
        this.adhocReminderDetails.monthsLead = this.formData.sendreminder && this.formData.sendreminder.type === 'M' ? this.formData.sendreminder.value : null;
        this.adhocReminderDetails.monthlyFrequency = this.formData.sendreminder.type === 'M' ? this.formData.repeatEvery : null;
        this.adhocReminderDetails.dailyFrequency = this.formData.sendreminder.type === 'D' ? this.formData.repeatEvery : null;
        this.adhocReminderDetails.employeeFlag = this.formData.staff ? this.formData.staff : 0;
        this.adhocReminderDetails.signatoryFlag = this.formData.signatory ? this.formData.signatory : 0;
        this.adhocReminderDetails.criticalFlag = this.formData.criticalList ? this.formData.criticalList : 0;
        this.adhocReminderDetails.nameTypeId = this.formData.nameType ? this.formData.nameType.code : null;
        this.adhocReminderDetails.relationship = this.formData.relationship ? this.formData.relationship.code : null;
        this.adhocReminderDetails.sendElectronically = this.formData.emailToRecipients ? 1 : 0;
        this.adhocReminderDetails.emailSubject = this.formData.emailSubjectLine ? this.formData.emailSubjectLine : null;
    }

    maintainAdditionalNames = () => {
        if (this.formData.mySelf) {
            if (this.viewData.loggedInUser && (this.viewData.loggedInUser.key !== this.formData.responsibleName.key)) {
                const reminder = _.clone(this.adhocReminderDetails);
                reminder.employeeNo = this.viewData.loggedInUser.key;
                reminder.employeeFlag = false;
                reminder.signatoryFlag = false;
                reminder.criticalFlag = false;
                reminder.nameTypeId = null;
                reminder.relationship = null;
                reminder.taskPlannerRowKey = this.taskPlannerRowKey;
                this.adhocGenerateNameList.push(reminder);
            }
        }

        const otherAdhocName = this.formData.otherNames;
        if (otherAdhocName.length > 0) {
            const names = this.formData.names;
            const newNames = otherAdhocName.filter(({ key: id1 }) => !names.some(({ key: id2 }) => id2 === id1));
            _.each(newNames, (item: any) => {
                const saveOthers = _.clone(this.adhocReminderDetails);
                saveOthers.employeeNo = item.key;
                saveOthers.employeeFlag = false;
                saveOthers.signatoryFlag = false;
                saveOthers.criticalFlag = false;
                saveOthers.nameTypeId = null;
                saveOthers.relationship = null;
                saveOthers.taskPlannerRowKey = this.taskPlannerRowKey;
                this.adhocGenerateNameList.push(saveOthers);
            });
        }
    };

    close = () => {
        if (this.adhocForm.dirty) {
            this.modalRef = this.ipxNotificationService.openDiscardModal();
            this.modalRef.content.confirmed$.subscribe(() => {
                this.bsModalRef.hide();
                this.onClose$.next(true);
            });
        } else {
            this.bsModalRef.hide();
            this.onClose$.next(true);
        }
        if (this.saveCall) {
            this.taskPlannerService.onActionComplete$.next({ reloadGrid: true, unprocessedRowKeys: [] });
        }
    };
}