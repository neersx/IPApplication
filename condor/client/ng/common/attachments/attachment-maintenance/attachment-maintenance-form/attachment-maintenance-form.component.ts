import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnDestroy, OnInit, Output, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, ValidationErrors } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { DmsModalComponent } from 'common/case-name/dms-modal/dms-modal.component';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable, race } from 'rxjs';
import { of } from 'rxjs/internal/observable/of';
import { debounceTime, filter, map, take, takeUntil } from 'rxjs/operators';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { HideEvent, IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { AttachmentModel, AttachmentService } from '../../attachment.service';
import { AttachmentFileBrowserComponent } from '../attachment-file-browser/attachement-file-browser.component';
import { AttachmentFolderBrowserComponent } from '../attachment-folder-browser/attachment-folder-browser.component';

@Component({
  selector: 'attachment-maintenance-form',
  templateUrl: './attachment-maintenance-form.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [IpxDestroy]
})
export class AttachmentMaintenanceFormComponent implements OnInit, OnDestroy, AfterViewInit {
  @Input() activityAttachment: any;
  @Input() activityDetails: any;
  @Input() set addAnother(value: boolean) {
    this.isAddAnotherChecked = value;
  }
  @Input() set disabled(flag: boolean) {
    if (this._disabled && !flag) {
      this.enableDisableFormGroupControls(false);
      this._disabled = flag;
    }
    if (!this._disabled && flag) {
      this.enableDisableFormGroupControls(true);
      this._disabled = flag;
    }
  }
  @Input() set viewData(data: any) {
    this._viewData = data;
    if (data) {
      this.initComponent();
    } else {
      if (this.formGroup) {
        this.formGroup.reset();
      }
    }
    this.cdr.markForCheck();
  }
  @Input() set document(id: any) {
    this.onDocumentIdChange(id);
  }

  @Output() readonly hasValidChanges = new EventEmitter();
  @Output() readonly hasSavedChanges = new EventEmitter();
  @Output() readonly closeModal = new EventEmitter();

  formGroup: FormGroup;
  _viewData: any;

  _disabled = false;
  id: number;
  documentId: number;
  isFileStoredInDb: boolean;
  baseType: string;
  originalBaseType: string;
  data: any;
  confirmationMessage: string;
  changeSubscription: any;
  dataType: any = dataTypeEnum;
  initialValues: any;
  isAdding = false;
  isAddAnotherChecked = false;
  caseEventsQuery: any;
  currentDate: Date;
  caseEventsScope: any;
  fileBrowserModalRef: BsModalRef;
  hasSettings = true;
  categories = [];
  activityTypes = [];
  filePathWarning: any;
  hostTarget: string;
  canBrowse: boolean;
  canBrowseDms: boolean;
  @Input() translationPrefix;
  documentSettings: {
    filePath: string;
    fileName: string;
    activityType: any;
    activityCategory: any
  };
  private defaultFileName: string;
  private readonly isHosted: boolean = false;
  constructor(private readonly service: AttachmentService,
    private readonly formBuilder: FormBuilder,
    private readonly messagingService: WindowParentMessagingService,
    private readonly translateService: TranslateService,
    private readonly dateHelper: DateHelper,
    readonly cdr: ChangeDetectorRef,
    private readonly notificationService: IpxNotificationService,
    private readonly confirmService: NotificationService,
    private readonly modalService: IpxModalService,
    private readonly $destroy: IpxDestroy,
    private readonly translate: TranslateService,
    readonly rootScopeService: RootScopeService) {
    this.data = {};
    this.caseEventsQuery = this.eventsFor.bind(this);
    this.caseEventsScope = this.setCaseEventsScope.bind(this);
    this.currentDate = new Date();
    this.isHosted = rootScopeService.isHosted;
  }

  ngAfterViewInit(): void {
    this.setErrorForEvent();
  }

  ngOnInit(): void {
    this.documentSettings = {
      activityCategory: null,
      activityType: null,
      fileName: null,
      filePath: null
    };
  }
  initComponent = () => {
    this.getData();
    this.setDerivedBaseType();
    this.createFormGroup();
  };
  setDerivedBaseType(): void {
    if (this.baseType === 'activity') {
      if (!_.isNumber(this.id)) {
        if (_.isNumber(this.data.activityCaseId)) {
          this.id = this.data.activityCaseId;
          this.baseType = 'case';
        }
        if (_.isNumber(this.data.activityNameId)) {
          this.id = this.data.activityNameId;
          this.baseType = 'name';
        }
      }
    }
  }

  ngOnDestroy(): void {
    if (this.changeSubscription) {
      this.changeSubscription.unsubscribe();
    }
  }
  save = (): void => {
    const pre = (this.formGroup.controls.filePath.dirty) ? (this.documentId != null) ? this.service.validateDirectory$(this.formGroup.value.filePath) : this.service.validatePath$(this.formGroup.value.filePath) : of(true);
    pre.subscribe(result => {
      this.markValidationResult(result);
      if (this.formGroup.errors !== null) {

        return;
      }

      const attachment = this.getDataToSave();

      if (_.isNumber(attachment.eventCycle) && _.isNumber(this.data.currentCycle) && attachment.eventCycle > this.data.currentCycle) {
        this.formGroup.get('eventCycle').setErrors({ 'attachmentMaintenance.invalidCycle': true });
        this.formGroup.get('eventCycle').markAsDirty();

        this.cdr.markForCheck();

        return;
      }

      this.service.addOrUpdateAttachment$(this.baseType, this.id, attachment).subscribe((newValue) => {
        this.confirmService.success();
        this.data = newValue;
        this.hasSavedChanges.emit(true);
        if (this.isAdding && this.isAddAnotherChecked && !this._viewData.isAdHocGeneration) {
          if (this.originalBaseType !== 'activity') {
            this.data.activityId = null;
          }
          this.data.sequenceNo = null;
          this.formGroup.reset(this.initialValues);
          this.formGroup.markAsPristine();
        } else {
          this.messagingService.postLifeCycleMessage({ action: 'onNavigate', target: this.hostTarget, payload: true });
          this.closeModal.emit(true);
        }
      });
    });
  };

  revert = (): void => {
    this.formGroup.reset(this.initialValues);
    this.formGroup.controls.activityDate.setValue(this.data.activityId ? this.data.activityDate ? new Date(this.data.activityDate) : null : this.currentDate, { emitEvent: false });
    this.formGroup.markAsUntouched();
    this.formGroup.markAsPristine();

    this.setErrorForEvent();
    this.disableCycleIfRequired();

    this.hasValidChanges.emit(null);

    this.cdr.detectChanges();
  };

  browse = (): void => {
    if (this.canBrowse) {
      const openComponent = this.documentId != null ? AttachmentFolderBrowserComponent : AttachmentFileBrowserComponent;
      this.fileBrowserModalRef = this.modalService.openModal(openComponent, {
        animated: false,
        ignoreBackdropClick: true,
        backdrop: 'static',
        class: 'modal-xl',
        initialState: {
          filePathControl: this.formGroup.controls.filePath,
          hasSettings: this.hasSettings
        }
      });
    }
  };

  browseDms = (): void => {
    if (this.canBrowseDms) {
      let cls = 'modal-xl modal-dms';
      if (this.isHosted) {
        cls = cls + ' hybrid';
      }
      const modal = this.modalService.openModal(DmsModalComponent, {
        backdrop: 'static',
        class: cls,
        initialState: {
          caseKey: this._viewData.caseId,
          nameKey: this._viewData.nameId,
          isMaintainance: true
        }
      });
      (modal.content.onClose$ as Observable<string>).pipe(take(1)).subscribe((res: any) => {
        if (res && res.iwl) {
          this.formGroup.controls.filePath.setValue(res.iwl);
        }

        this.formGroup.controls.filePath.markAsDirty();
        this.formGroup.controls.filePath.markAsTouched();
      });
    }
  };

  private enableDisableFormGroupControls(isDisabling: boolean): void {
    if (this.formGroup) {
      setTimeout(() => {
        if (!isDisabling) {
          this.formGroup.controls.attachmentName.enable();
          this.formGroup.controls.attachmentDescription.enable();
          this.formGroup.controls.allowClientAccess.enable();
          this.formGroup.controls.filePath.enable();
          this.formGroup.controls.fileName.enable();
          this.formGroup.controls.activityType.enable();
          this.formGroup.controls.activityCategory.enable();
          this.formGroup.controls.activityDate.enable();
          this.formGroup.controls.attachmentType.enable();
          this.formGroup.controls.language.enable();
          this.formGroup.controls.activityDate.setValue(this.data.activityId ? this.data.activityDate ? new Date(this.data.activityDate) : null : this.currentDate, { emitEvent: false });
          if (this.baseType === 'case') {
            this.formGroup.controls.event.enable();
            this.formGroup.controls.eventCycle.enable();
            this.formGroup.controls.pageCount.enable();
          }
        } else {
          this.formGroup.reset();
          this.formGroup.controls.attachmentName.disable();
          this.formGroup.controls.attachmentDescription.disable();
          this.formGroup.controls.allowClientAccess.disable();
          this.formGroup.controls.filePath.disable();
          this.formGroup.controls.fileName.disable();
          this.formGroup.controls.activityType.disable();
          this.formGroup.controls.activityCategory.disable();
          this.formGroup.controls.activityDate.disable();
          this.formGroup.controls.attachmentType.disable();
          this.formGroup.controls.language.disable();
          if (this.baseType === 'case') {
            this.formGroup.controls.event.disable();
            this.formGroup.controls.eventCycle.disable();
            this.formGroup.controls.pageCount.disable();
          }
        }

        this.updateDeliverySettingsInFields();
        this.updateActivity();
      }, 100);
    }
  }
  private onDocumentIdChange(documentId: any): void {
    if (documentId) {
      this.documentId = documentId;
      this.getDeliverySettings(documentId);
      this.getActivity(documentId);
    } else {
      if (this.formGroup) {
        this.formGroup.reset();
      }
    }
    this.cdr.markForCheck();
  }
  private readonly updateActivity = () => {
    if (!this._disabled && this.documentSettings && this.documentSettings.activityType) {
      this.formGroup.controls.activityType.setValue(this.documentSettings.activityType);
      this.formGroup.controls.activityType.markAsDirty();
      this.formGroup.controls.activityType.markAsTouched();
    } else {
      this.formGroup.controls.activityType.setValue('');
      this.formGroup.controls.activityType.markAsPristine();
    }
    if (!this._disabled && this.documentSettings && this.documentSettings.activityCategory) {
      this.formGroup.controls.activityCategory.setValue(this.documentSettings.activityCategory);
      this.formGroup.controls.activityCategory.markAsDirty();
      this.formGroup.controls.activityCategory.markAsTouched();
    } else {
      this.formGroup.controls.activityCategory.setValue('');
      this.formGroup.controls.activityCategory.markAsPristine();
    }
  };
  private readonly updateDeliverySettingsInFields = () => {
    if (!this._disabled && this.documentSettings && this.documentSettings.filePath) {
      this.formGroup.controls.filePath.setValue(this.documentSettings.filePath);
      this.formGroup.controls.filePath.markAsDirty();
      this.formGroup.controls.filePath.markAsTouched();
    } else {
      this.formGroup.controls.filePath.setValue('');
      this.formGroup.controls.filePath.markAsPristine();
    }

    if (this._disabled) {
      this.formGroup.controls.fileName.setValue('');
      this.formGroup.controls.fileName.markAsPristine();
    } else {
      if (this.documentSettings && this.documentSettings.fileName) {
        this.formGroup.controls.fileName.setValue(this.documentSettings.fileName);
      } else {
        this.formGroup.controls.fileName.setValue(this.defaultFileName);
      }
      this.formGroup.controls.fileName.markAsDirty();
      this.formGroup.controls.fileName.markAsTouched();
    }
  };

  private readonly getDeliverySettings = (documentId: any) => {
    this.service.getDeliveryDestination$(this.baseType, this.id, documentId).subscribe((resp) => {
      if (resp) {
        this.documentSettings.filePath = resp.directoryName;
        this.documentSettings.fileName = resp.fileName || this.defaultFileName;
      }
      this.updateDeliverySettingsInFields();
    });
  };

  private readonly getActivity = (documentId: any) => {
    this.service.getActivity$(this.baseType, this.id, documentId).subscribe((resp) => {
      if (resp) {
        this.documentSettings.activityType = resp.activityType;
        this.documentSettings.activityCategory = resp.activityCategory;
      }
      this.updateActivity();
    });
  };

  private readonly subscribeChanges = () => {
    this.hasValidChanges.emit(this.formGroup.dirty ? (this.formGroup.valid && this.formGroup.errors == null) ? true : false : null);
  };

  private readonly getDataToSave = (): AttachmentModel => {
    const attachment = new AttachmentModel({
      documentId: this.documentId,
      activityId: this.data.activityId,
      sequenceNo: this.data.sequenceNo,
      activityCategoryId: this.formGroup.value.activityCategory,
      activityDate: this.formGroup.value.activityDate ? this.dateHelper.toLocal(this.formGroup.value.activityDate) : null,
      activityType: this.formGroup.value.activityType,
      attachmentName: this.formGroup.value.attachmentName,
      attachmentDescription: this.formGroup.value.attachmentDescription,
      filePath: this.formGroup.value.filePath,
      fileName: this.formGroup.value.fileName,
      isPublic: this.formGroup.value.allowClientAccess,
      attachmentType: this.formGroup.value.attachmentType ? this.formGroup.value.attachmentType.key : null,
      language: this.formGroup.value.language ? this.formGroup.value.language.key : null
    });

    if (this.baseType === 'case') {
      attachment.eventId = this.formGroup.value.event && _.isNumber(this.formGroup.value.event.key) ? this.formGroup.value.event.key : null;
      attachment.eventCycle = attachment.eventId !== null && this.formGroup.get('eventCycle').value ? +this.formGroup.get('eventCycle').value : null;

      attachment.pageCount = this.formGroup.value.pageCount;
    }

    if (this.baseType === 'priorArt') {
      attachment.pageCount = this.formGroup.value.pageCount;
    }

    return attachment;
  };

  private createFormGroup(): void {

    this.formGroup = this.formBuilder.group({
      attachmentName: new FormControl({ value: this.data.attachmentName, disabled: this._disabled }),
      attachmentDescription: new FormControl({ value: this.data.attachmentDescription, disabled: this._disabled }),
      allowClientAccess: new FormControl({ value: this.data.isPublic ? this.data.isPublic : false, disabled: this._disabled }),
      filePath: new FormControl({ value: this.data.filePath, disabled: this._disabled }),
      fileName: new FormControl({ value: this.data.fileName, disabled: this._disabled }),
      activityType: new FormControl({ value: this.data.activityType, disabled: this._disabled }),
      activityCategory: new FormControl({ value: this.data.activityCategoryId, disabled: this._disabled }),
      activityDate: new FormControl({ value: this.data.activityDate ? new Date(this.data.activityDate) : null, disabled: this._disabled }),
      attachmentType: new FormControl({ value: this.data.attachmentType ? { key: this.data.attachmentType, value: this.data.attachmentTypeDescription } : {}, disabled: this._disabled }),
      language: new FormControl({ value: this.data.language ? { key: this.data.language, value: this.data.languageDescription } : {}, disabled: this._disabled })
    }, {
      validators: [this._checkEventCycle]
    });

    if (this.baseType === 'case') {
      this.formGroup.addControl('event', new FormControl({ value: this.data.eventId ? { key: this.data.eventId, value: this.data.eventDescription } : {}, disabled: this._disabled }));

      this.formGroup.addControl('eventCycle', new FormControl({ value: this.data.eventCycle, disabled: this._disabled }));

      this.formGroup.addControl('pageCount', new FormControl({ value: this.data.pageCount, disabled: this._disabled }));

      this.formGroup.get('event').valueChanges
        .pipe(takeUntil(this.$destroy))
        .subscribe(this.handleEventChange);
    }

    if (this.baseType === 'priorArt') {
      this.formGroup.addControl('pageCount', new FormControl({ value: this.data.pageCount, disabled: this._disabled }));
    }

    this.initialValues = this.formGroup.value;

    this.disableCycleIfRequired();

    this.changeSubscription = this.formGroup.statusChanges.subscribe(() => {
      this.subscribeChanges();
    });

    if (this.hasSettings) {
      this.formGroup.controls.filePath.valueChanges.pipe(debounceTime(800)).subscribe(result => {
        this.filePathWarning = '';
        this.validatePathOrFolder(result);

        this.cdr.markForCheck();
      });
    }
  }
  private validatePathOrFolder(r: any): void {
    const call = this.documentId != null ? this.service.validateDirectory$(r) : this.service.validatePath$(r);
    call.subscribe(result => {
      this.markValidationResult(result);
    });
  }

  private readonly markValidationResult = (result: any) => {
    if (this.documentId != null) {
      if (result) {
        if (!result.directoryExists) {
          this.filePathWarning = 'documentGeneration.generateWord.invalidFolderWillGenerate';
        }

        if (!result.isLinkedToStorageLocation) {
          this.formGroup.controls.filePath.setErrors({ 'attachmentMaintenance.invalidFolder': true });
        }

        return;
      }
      this.formGroup.controls.filePath.setErrors(null);
    } else {
      if (!result) {
        this.formGroup.controls.filePath.setErrors({ 'attachmentMaintenance.invalidPath': true });

        return;
      }
      this.formGroup.controls.filePath.setErrors(null);
    }
  };

  private readonly disableCycleIfRequired = (): void => {
    if (!!this.formGroup.controls.event && Object.keys(this.formGroup.value.event).length === 0) {
      this.formGroup.get('eventCycle').disable();
    }

    if (this.baseType === 'case' && !this.data.eventIsCyclic && !!this.data.eventCycle) {
      this.formGroup.get('eventCycle').disable();
    }
  };
  private readonly handleEventChange = (eventDetails): void => {
    const eventCycleElem = this.formGroup.get('eventCycle');

    if (!eventDetails) {
      eventCycleElem.setValue('');
      eventCycleElem.enable();
    } else {
      eventCycleElem.setValue(eventDetails.currentCycle);
      this.data.currentCycle = eventDetails.currentCycle;
      if (eventDetails.maxCycles === 1) {
        eventCycleElem.disable();
      } else {
        eventCycleElem.enable();
      }
    }

    this.cdr.markForCheck();
  };

  private readonly _checkEventCycle = (c: FormGroup): ValidationErrors | null => {
    if (!c || !this || !this.formGroup || !this.formGroup.get('event') || !this.formGroup.get('eventCycle')) {
      return null;
    }

    if (!!this.formGroup.get('event').value && !!this.formGroup.get('event').value.key) {
      if (!this.formGroup.get('eventCycle').value) {
        this.formGroup.get('eventCycle').setErrors({ required: true });
        this.formGroup.get('eventCycle').markAsDirty();

        return undefined;
      }
      const cycle = this.formGroup.get('eventCycle').value;
      if (cycle % 1 > 0) {
        this.formGroup.get('eventCycle').setErrors({ wholeinteger: true });

        return undefined;
      }
      if (isNaN(cycle) || cycle < 1) {
        this.formGroup.get('eventCycle').setErrors({ positiveinteger: true });

        return undefined;
      }
    }

    this.formGroup.get('eventCycle').setErrors(null);

    return null;
  };

  private readonly getData = () => {
    this.id = this._viewData.id;
    this.baseType = this._viewData.baseType;
    this.hasSettings = this._viewData.hasAttachmentSettings;
    this.originalBaseType = this._viewData.baseType;
    this.categories = this._viewData.categories;
    this.activityTypes = this._viewData.activityTypes;
    this.defaultFileName = this._viewData.defaultFileName;
    this.canBrowse = this._viewData.canBrowse;
    this.canBrowseDms = this._viewData.canBrowseDms && !!this._viewData.caseId;

    this.confirmationMessage = this.translateService.instant('attachmentsIntegration.discardMessage');
    this.isAdding = this._viewData.isAdHocGeneration ? true : this.activityAttachment ? false : true;
    this.hostTarget = this._viewData.isAdHocGeneration ? 'generateDocument' : 'attachmentMaintenanceHost';
    this.isFileStoredInDb = this.activityAttachment ? this.activityAttachment.isFileStoredInDb : false;
    this.data = this.activityAttachment ? this.activityAttachment
      : {
        ...{
          activityId: null,
          sequence: null,
          attachmentName: '',
          attachmentDescription: '',
          isPublic: false,
          filePath: '',
          activityType: null,
          activityCategoryId: null,
          activityDate: this.currentDate,
          attachmentType: null,
          language: null,
          pageCount: ''
        },
        ...AttachmentMaintenanceFormComponent.getEventDetails(this._viewData)
      };

    if (!!this.activityDetails) {
      this.data = { ...this.data, ...this.activityDetails };
    }

    if ((this.originalBaseType === 'activity' || this.isAdding) && !!this._viewData && !!this._viewData.event) {
      this.data = { ...this.data, ...AttachmentMaintenanceFormComponent.getEventDetails(this._viewData) };
    }
  };

  private static getEventDetails(baseViewData: any): any {
    if (!!baseViewData.event) {
      const viewData = { ...{ id: null, description: '', isCyclic: true, cycle: null, isCaseEvent: true }, ...baseViewData };

      return {
        eventId: viewData.event.id,
        eventDescription: viewData.event.description,
        eventIsCyclic: viewData.event.isCyclic,
        eventCycle: viewData.event.cycle || (viewData.activityDetails || {}).eventCycle,
        isCaseEvent: viewData.event.isCaseEvent,
        currentCycle: viewData.event.currentCycle
      };
    }

    return {};
  }

  setErrorForEvent(): void {
    if (this.data && _.isNumber(this.data.eventId) && !this.data.isCaseEvent) {
      this.formGroup.get('event').setErrors({ 'attachmentMaintenance.eventNotFound': true });
      this.formGroup.get('event').markAsDirty();
    }
  }

  eventsFor(query: any): any {
    const caseKey = this._viewData.caseId;
    const actionKey = !!this._viewData.actionKey ? this._viewData.actionKey : '';
    const extended = _.extend({}, query, {
      caseId: caseKey,
      actionId: actionKey
    });

    return extended;
  }

  setCaseEventsScope(): any {
    if (!!this._viewData.actionName) {
      return {
        label: this.translate.instant('caseview.attachments.action'),
        value: this._viewData.actionName
      };
    }
  }
  deleteAttachment(): void {
    const notificationRef = this.notificationService.openDeleteConfirmModal('attachmentsIntegration.deleteConfirmation');

    const closedWithoutConfirm = this.notificationService.onHide$.pipe(filter((n: HideEvent) => n.isCancelOrEscape), map(a => false));
    const confirmed = notificationRef.content.confirmed$.pipe(map(c => true));

    race(closedWithoutConfirm, confirmed)
      .pipe(take(1), takeUntil(this.$destroy))
      .subscribe((isConfirmed: boolean) => {
        if (isConfirmed) {
          this.service.deleteAttachment(this.baseType, this.id, this.data, this.originalBaseType === 'activity')
            .pipe(take(1), takeUntil(this.$destroy))
            .subscribe((res) => {
              this.confirmService.success('attachmentsIntegration.deleteSuccess');
              this.messagingService.postLifeCycleMessage({ action: 'onNavigate', target: 'attachmentMaintenanceHost', payload: true });
              this.closeModal.emit(true);
            });
        }
      });
  }
}
