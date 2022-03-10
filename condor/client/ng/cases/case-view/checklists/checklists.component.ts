import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, NgForm, RequiredValidator, Validators } from '@angular/forms';
import { WarningService } from 'accounting/warnings/warning-service';
import { WipWarningData } from 'accounting/warnings/warnings-model';
import { CasenamesWarningsComponent } from 'accounting/warnings/warnings.module';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { LocalSettings } from 'core/local-settings';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { filter, map, take, takeWhile } from 'rxjs/operators';
import { GridFocusDirective } from 'shared/component/grid/ipx-grid-focus.directive';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { HideEvent, IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { HostChildComponent } from 'shared/component/page/host-child-component';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { CaseDetailService } from '../case-detail.service';
import { ChecklistHostComponent, ChecklistTypes } from './checklist-model';
import { RegenerateChecklistComponent } from './regeneration/regenerate-checklist';

@Component({
  selector: 'app-checklists',
  templateUrl: './checklists.component.html',
  styleUrls: ['./checklists.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ChecklistsComponent implements OnInit, HostChildComponent {
  @ViewChild('checklistForm', { static: true }) form: NgForm;
  @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
  @ViewChild('ipxKendoGridRef', { static: false, read: GridFocusDirective }) _gridFocus: GridFocusDirective;
  gridOptions: IpxGridOptions;
  topic: Topic;
  @Input() data: any;
  caseId: number;
  hasValidChecklistTypes: boolean;
  selectedChecklistTypeId: number;
  selectedCriteriaKey: number;
  hasGeneralDocuments: boolean;
  checklistCriteriaGeneralDocs: any = [];
  checklistTypeDocuments: any;
  checklistTypes: Array<ChecklistTypes>;
  hasChangedAnswers: boolean;
  rowEditUpdates: { [rowKey: string]: any };
  originalData: any;
  isHosted: boolean;
  onRequestDataResponseReceived = {} as any;
  previousSelectedChecklistTypeId: any;
  today: Date = new Date();
  isValidData: boolean;
  modalRef: BsModalRef;
  hostingComponent: any;
  cachedData: any = {};
  gridCacheddata: any = [];
  onChangeAction: () => void;
  onNavigationAction: (e: any) => void;
  isRegeneratedPopupShown: boolean;

  constructor(private readonly service: CaseDetailService,
    private readonly cdr: ChangeDetectorRef,
    private readonly localSettings: LocalSettings,
    private readonly windowParentMessagingService: WindowParentMessagingService,
    private readonly rootScopeService: RootScopeService,
    private readonly formBuilder: FormBuilder,
    private readonly warningService: WarningService,
    private readonly modalService: IpxModalService,
    private readonly notificationService: IpxNotificationService,
    private readonly dateHelper: DateHelper) {
  }

  ngOnInit(): void {
    this.caseId = this.topic.params.viewData.caseKey;
    this.isHosted = this.rootScopeService.isHosted;
    this.hostingComponent = this.topic.params.viewData.hostId;
    this.isValidData = true;
    this.isRegeneratedPopupShown = false;
    this.service.getCaseChecklistTypes$(this.caseId)
      .subscribe(response => {
        if (Array.isArray(response.checklistTypes) && response.checklistTypes.length) {
          this.checklistTypes = response.checklistTypes;
          this.hasValidChecklistTypes = true;
          let genericKeyExists = false;
          if (this.topic.params.viewData.genericKey !== undefined) {
            const selectedChecklistinWeb = _.where(response.checklistTypes, {
              checklistType: this.topic.params.viewData.genericKey
            });
            genericKeyExists = selectedChecklistinWeb.length > 0;
          }
          if (this.isHosted && genericKeyExists) {
            if (this.cachedData.checklistTypeId !== undefined) {
              if (this.topic.params.viewData.genericKey !== this.cachedData.checklistTypeId) {
                this.setSelectedChecklistType(this.cachedData.checklistTypeId);
                this.selectedCriteriaKey = this.cachedData.checklistCriteriaKey;
                this.selectedChecklistTypeId = this.cachedData.checklistTypeId;
              }
            } else {
              this.setSelectedChecklistType(this.topic.params.viewData.genericKey);
              this.selectedChecklistTypeId = this.topic.params.viewData.genericKey;
              const selectedChecklistRow = _.where(this.checklistTypes, {
                checklistType: this.topic.params.viewData.genericKey
              });
              this.selectedCriteriaKey = selectedChecklistRow[0].checklistCriteriaKey;
            }
          } else {
            this.setSelectedChecklistType(response.selectedChecklistType);
            this.selectedCriteriaKey = response.selectedChecklistCriteriaKey;
          }
          this.gridOptions = this.buildGridOptions();
          if (this.isHosted) {
            this.getGeneralDocuments();
            if (this.hostingComponent === ChecklistHostComponent.ChecklistHost) {
              this.warningService.restrictOnWip = true;
              this.warningService.getCasenamesWarnings(this.caseId, this.today).subscribe((warningResponse: WipWarningData) => {
                if (!warningResponse) {
                  return;
                }
                const caseNamesRes = warningResponse.caseWipWarnings;
                if (!!warningResponse.budgetCheckResult || (!!warningResponse.prepaymentCheckResult && warningResponse.prepaymentCheckResult.exceeded) || !!warningResponse.billingCapCheckResult || caseNamesRes.length && _.any(caseNamesRes, cn => {
                  return cn.caseName.debtorStatusActionFlag !== null || (cn.creditLimitCheckResult && cn.creditLimitCheckResult.exceeded);
                })) {
                  const data = { caseNames: caseNamesRes, budgetCheckResult: warningResponse.budgetCheckResult, selectedEntryDate: this.today, prepaymentCheckResult: warningResponse.prepaymentCheckResult, billingCapCheckResults: warningResponse.billingCapCheckResult };
                  this.modalRef = this.modalService.openModal(CasenamesWarningsComponent, { animated: false, ignoreBackdropClick: true, class: 'modal-lg', initialState: data });
                  this.modalService.onHide$.pipe(filter((e: HideEvent) => e.isCancelOrEscape), takeWhile(() => !!this.modalRef))
                    .subscribe(() => this._handleCaseNameWarningConfirmation(false));

                  this.modalRef.content.btnClicked.pipe(takeWhile(() => !!this.modalRef))
                    .subscribe((proceed: boolean) => this._handleCaseNameWarningConfirmation(proceed));

                  this.modalRef.content.onBlocked.pipe(takeWhile(() => !!this.modalRef))
                    .subscribe((isBlockedState: boolean) => this._handleCaseNameWarningConfirmation(!isBlockedState));
                }
              });
            }
          }
          this.cdr.detectChanges();
        } else {
          this.hasValidChecklistTypes = false;
        }
      });
    this.service.hasPendingChanges$.subscribe(() => {
      this.cdr.markForCheck();
    });
    this.service.resetChanges$.subscribe((val: boolean) => {
      if (val) {
        this.resetForms();
      }
    });
  }

  _handleCaseNameWarningConfirmation(accepted: boolean): void {
    if (accepted) {

      return;
    }

    this.windowParentMessagingService.postLifeCycleMessage({
      action: 'onChange',
      target: this.hostingComponent,
      payload: {
        close: true
      }
    });
  }

  private resetForms(): void {
    this.grid.rowEditFormGroups = null;
    this.grid.search();
    if (this.isHosted) {
      this.windowParentMessagingService.postLifeCycleMessage({
        action: 'onChange',
        target: this.hostingComponent,
        payload: {
          isDirty: false
        }
      });
    }
    this.isValidData = true;
    this.gridOptions.formGroup.markAsPristine();
  }

  changeChecklistType = (): void => {
    if (this.anyChanges()) {
      const modal = this.notificationService.openDiscardModal();
      modal.content.confirmed$.pipe(take(1)).subscribe(() => {
        this.loadChecklistOnChange();
        if (this.isHosted) {
          this.windowParentMessagingService.postLifeCycleMessage({
            action: 'onChange',
            target: this.hostingComponent,
            payload: {
              isDirty: false
            }
          });
        }
        this.service.hasPendingChanges$.next(false);
      });
      modal.content.cancelled$.pipe(take(1)).subscribe(() => {
        this.setSelectedChecklistType(this.previousSelectedChecklistTypeId);
        this.cdr.detectChanges();
      });

      return;
    }
    this.loadChecklistOnChange();
  };

  private readonly loadChecklistOnChange = (): void => {
    const checklistType = _.find(this.checklistTypes, (n: any) => {
      return n.checklistType === this.selectedChecklistTypeId;
    });
    this.selectedCriteriaKey = checklistType.checklistCriteriaKey;
    this.grid.rowEditFormGroups = {};
    this.gridOptions._search();
    this.previousSelectedChecklistTypeId = this.selectedChecklistTypeId;
    this.hasGeneralDocuments = false;
    this.getGeneralDocuments();
  };

  private readonly getGeneralDocuments = (): void => {
    if (this.caseId && this.selectedCriteriaKey) {
      this.service.getChecklistDocuments$(this.caseId, this.selectedCriteriaKey).subscribe((checklistDocuments) => {
        if (checklistDocuments) {
          if (checklistDocuments.length > 0) {
            this.hasGeneralDocuments = true;
            this.checklistCriteriaGeneralDocs = checklistDocuments;
            this.checklistTypeDocuments = _.pluck(checklistDocuments, 'documentName').join(', ');
          }
        }
      });
    }
  };

  private readonly buildGridOptions = (): IpxGridOptions => {
    let options: IpxGridOptions = {
      selectable: {
        mode: 'single'
      },
      sortable: false,
      showGridMessagesUsingInlineAlert: false,
      autobind: true,
      persistSelection: false,
      reorderable: true,
      enableGridAdd: false,
      navigable: false,
      pageable: this.getPaging(),
      gridMessages: {
        noResultsFound: 'grid.messages.noItems',
        performSearch: ''
      },
      read$: (queryParams) => {
        if (this.isHosted) {
          let gridData: any;

          return this.service
            .getCaseChecklistDataHybrid$(this.caseId, this.selectedCriteriaKey)
            .pipe(map((res: any) => {
              gridData = res;
              if (this.gridCacheddata.length > 0) {
                gridData = this.setCachedData(gridData);
              }

              return gridData;
            }));
        }

        return this.service.getCaseChecklistData$(this.caseId, this.selectedCriteriaKey, queryParams);
      },
      onDataBound: (boundData: any) => {
        if (!!boundData && boundData.length > 0 && this.isHosted) {
          this.dataBound(boundData);
          setTimeout(() => {
            this._gridFocus.focusFirstEditableField();
          }, 10);
        }
      },
      columns: this.getColumns(),
      columnSelection: {
        localSetting: this.localSettings.keys.caseView.checklist.columnsSelection
      }
    };

    if (this.isHosted) {
      options = {
        ...options,
        // tslint:disable-next-line: unnecessary-bind
        createFormGroup: this.createFormGroup.bind(this),
        rowMaintenance: {
          rowEditKeyField: 'questionNo'
        },
        alwaysRenderInEditMode: true
      };
    }

    return options;
  };

  createFormGroup = (dataItem: any): FormGroup => {

    const formGroup = this.formBuilder.group({
      question: dataItem.question,
      questionId: dataItem.questionNo,
      yesUpdateEventId: dataItem.yesEventNumber,
      yesDueDateFlag: dataItem.yesDueDateFlag,
      yesRateId: dataItem.yesRateNumber,
      noUpdateEventId: dataItem.noEventNumber,
      noDueDateFlag: dataItem.noDueDateFlag,
      noRateId: dataItem.noRateNumber,
      periodTypeKey: dataItem.periodTypeKey,
      yesNoOption: dataItem.yesNoOption,
      isProcessed: dataItem.isProcessed,
      hasLetters: !!dataItem.letters,
      hasNoCharge: !!dataItem.noRateNumber,
      hasYesCharge: !!dataItem.yesRateNumber,
      sourceQuestionId: dataItem.sourceQuestionId,
      yesAnswer: this.setDefaultedFormControl('yes', dataItem),
      noAnswer: this.setDefaultedFormControl('no', dataItem),
      textValue: new FormControl(dataItem.textValue, dataItem.textOption === 1 ? [Validators.required] : null),
      countValue: new FormControl(dataItem.countValue, dataItem.countOption === 1 ? [Validators.required] : null),
        dateValue: new FormControl(!dataItem || !dataItem.dateValue ? null : new Date(dataItem.dateValue), ((dataItem.yesAnswer && dataItem.yesEventNumber !== null) || (dataItem.noAnswer && dataItem.noEventNumber !== null)) ? [Validators.required] : null),
      staffName: new FormControl(!dataItem || !dataItem.staffNameKey ? null : {
        key: dataItem.staffNameKey,
        displayName: dataItem.staffName
      }, dataItem.staffNameOption === 1 ? [Validators.required] : null),
      amountValue: new FormControl(!dataItem.amountValue ? null : parseFloat(dataItem.amountValue.toFixed(2)), dataItem.amountOption === 1 ? [Validators.required] : null),
      listSelection: new FormControl(!dataItem.listSelectionKey ? null : dataItem.listSelectionKey.toString())
    });
    this.gridOptions.formGroup = formGroup;
    this.cdr.markForCheck();

    return formGroup;
  };

  changeAnswer = (caller: string, rowdata: any, fg: FormGroup, dataItem: any) => {
      if (caller === 'dateValue') {
          if (rowdata !== null && fg.controls.dateValue.value !== new Date(rowdata)) {
              if ((fg.controls.noAnswer.value && fg.controls.noUpdateEventId.value) || (fg.controls.yesAnswer.value && fg.controls.yesUpdateEventId.value)) {
                  if (!fg.controls.dateValue.value) {
                      fg.controls.dateValue.setErrors({
                          required: true
                      });
                      fg.controls.dateValue.markAsDirty();
                      fg.controls.dateValue.markAsTouched();
                      fg.controls.dateValue.setValue(null);
                  } else {
                      fg.controls.dateValue.setErrors(null);
                  }
              } else {
                  fg.controls.dateValue.setErrors(null);
              }
          }
      } else {
          this.processYesNo(caller, fg, dataItem);
      }
      this.checkValidationAndEnableSave();
  };

    private readonly processYesNo = (caller: string, fg: FormGroup, dataItem: any): void => {
        let childQuestions: any;
        let hasChildQuestion = false;
        if (dataItem) {
            childQuestions = _.where(this.originalData, {
                sourceQuestionId: dataItem.questionNo
            });
            hasChildQuestion = childQuestions.length > 0;
        }
        if (caller === 'yes') {
            if (fg.controls.yesAnswer.value) {
                fg.controls.noAnswer.setValue(false);
                if (dataItem.yesDateOption && !fg.controls.dateValue.value) {
                    fg.controls.dateValue.setValue(this.service.eventDate(this.today));
                }
                if (fg.controls.yesUpdateEventId.value && !fg.controls.dateValue.value) {
                    fg.controls.dateValue.setErrors({ required: true });
                } else {
                    fg.controls.dateValue.setErrors(null);
                }
            } else {
                fg.controls.dateValue.setValue(null);
            }
            if (hasChildQuestion) {
                this.processChildQuestions(childQuestions, 'yes', fg.controls.yesAnswer.value);
            }
        } else if (caller === 'no') {
            if (fg.controls.noAnswer.value) {
                fg.controls.yesAnswer.setValue(false);
                if (dataItem.noDateOption && !fg.controls.dateValue.value) {
                    fg.controls.dateValue.setValue(this.service.eventDate(this.today));
                }
                if (fg.controls.noUpdateEventId.value && !fg.controls.dateValue.value) {
                    fg.controls.dateValue.setErrors({ required: true });
                } else {
                    fg.controls.dateValue.setErrors(null);
                }
            } else {
                fg.controls.dateValue.setValue(null);
            }
            if (hasChildQuestion) {
                this.processChildQuestions(childQuestions, 'no', fg.controls.noAnswer.value);
            }
        }
    };

  private readonly processChildQuestions = (childQuestions: any, answerType: string, parentValue: boolean): void => {
    let childQuestionFormGroup: any = [];
    _.each(childQuestions, (childQuestion: any) => {
      if (childQuestion) {
        childQuestionFormGroup = _.find(this.grid.rowEditFormGroups, (t: any) => {
          return t.controls.questionId.value === childQuestion.questionNo;
        });
        this.setDefaultedYesNoAnswer(answerType, childQuestion, childQuestionFormGroup, parentValue);
      }
    });

    return childQuestionFormGroup;
  };

  dataBound = (originalData: Array<any>): void => {
    this.originalData = originalData;
  };

  setCachedData = (gridData: Array<any>): Array<any> => {
    let counter = 0;
    gridData.forEach((row: any) => {
      const question: any = _.where(this.gridCacheddata, {
        questionId: row.questionNo
      });
      if (question.length > 0) {
        gridData[counter].textValue = question[0].textValue;
        gridData[counter].yesEventNumber = question[0].yesUpdateEventId;
        gridData[counter].yesDueDateFlag = question[0].yesDueDateFlag;
        gridData[counter].yesRateNumber = question[0].yesRateId;
        gridData[counter].noEventNumber = question[0].noUpdateEventId;
        gridData[counter].noDueDateFlag = question[0].noDueDateFlag;
        gridData[counter].noRateNumber = question[0].noRateId;
        gridData[counter].periodTypeKey = question[0].periodTypeKey;
        gridData[counter].yesNoOption = question[0].yesNoOption;
        gridData[counter].isProcessed = question[0].isProcessed;
        gridData[counter].sourceQuestionId = question[0].sourceQuestionId;
        gridData[counter].yesAnswer = question[0].yesAnswer;
        gridData[counter].noAnswer = question[0].noAnswer;
        gridData[counter].countValue = question[0].countValue;
        gridData[counter].dateValue = !question[0].dateValue ? null : this.service.eventDate(new Date(question[0].dateValue));
        if (question[0].staffName !== null) {
          gridData[counter].staffNameKey = question[0].staffName.key;
          gridData[counter].staffName = question[0].staffName.displayName;
          gridData[counter].staffNameCode = question[0].staffName.code;
        }
        gridData[counter].amountValue = question[0].amountValue;
        gridData[counter].listSelectionKey = question[0].listSelection;
      }
      counter++;
    });

    return gridData;
  };

  // tslint:disable-next-line: cyclomatic-complexity
  setDefaultedFormControl = (caller: string, dataItem: any): FormControl => {
    let checkboxValue = false;
    let disabledValue = !dataItem.yesNoOption;
    let sourceQuestion;
    if (dataItem.sourceQuestionId !== null) {
      sourceQuestion = _.find(this.originalData, (t: any) => {
        return t.questionNo === dataItem.sourceQuestionId;
      });
    }

    if (caller === 'yes') {
      if (dataItem.yesAnswer) {
        checkboxValue = true;
        if (sourceQuestion && !dataItem.isAnswered) {
          checkboxValue = ((sourceQuestion.yesAnswer || sourceQuestion.yesNoOption === 4) && (dataItem.answerSourceYes === 4 || dataItem.answerSourceYes === 6)) ||
            ((sourceQuestion.noAnswer || sourceQuestion.yesNoOption === 5) && (dataItem.answerSourceNo === 4 || dataItem.answerSourceNo === 6)) ? true : false;
          if (!checkboxValue) {
            dataItem.yesAnswer = false;
          }
          dataItem.isAnswered = false;
        } else {
          dataItem.isAnswered = true;
        }
      } else if (!dataItem.yesAnswer && !dataItem.noAnswer && !dataItem.isAnswered && dataItem.yesNoOption === 4) {
        checkboxValue = true;
        dataItem.isAnswered = true;
      } else if (!dataItem.yesAnswer && !dataItem.noAnswer && !dataItem.isAnswered && dataItem.sourceQuestionId !== null) {
        if (sourceQuestion) {
          if ((sourceQuestion.yesAnswer || sourceQuestion.yesNoOption === 4) && (dataItem.answerSourceYes === 4 || dataItem.answerSourceYes === 6)) {
            checkboxValue = true;
          } else if ((sourceQuestion.noAnswer || sourceQuestion.yesNoOption === 5) && (dataItem.answerSourceNo === 4 || dataItem.answerSourceNo === 6)) {
            checkboxValue = true;
          }
          if ((dataItem.answerSourceNo === 8 && sourceQuestion.noAnswer) || (dataItem.answerSourceYes === 8 && sourceQuestion.yesAnswer)) {
            checkboxValue = false;
          }
        }
      }
    } else if (caller === 'no') {
      if (dataItem.noAnswer) {
        checkboxValue = true;
        if (sourceQuestion && !dataItem.isAnswered) {
          checkboxValue = ((sourceQuestion.noAnswer || sourceQuestion.yesNoOption === 5) && (dataItem.answerSourceNo === 5 || dataItem.answerSourceNo === 7)) ||
            ((sourceQuestion.yesAnswer || sourceQuestion.yesNoOption === 4) && (dataItem.answerSourceYes === 5 || dataItem.answerSourceYes === 7)) ? true : false;
        }
        dataItem.isAnswered = true;
      } else if (!dataItem.yesAnswer && !dataItem.noAnswer && !dataItem.isAnswered && dataItem.yesNoOption === 5) {
        checkboxValue = true;
        dataItem.isAnswered = true;
      } else if (!dataItem.yesAnswer && !dataItem.noAnswer && !dataItem.isAnswered && dataItem.sourceQuestionId !== null) {
        if (sourceQuestion) {
          checkboxValue = ((sourceQuestion.noAnswer || sourceQuestion.yesNoOption === 5) && (dataItem.answerSourceNo === 5 || dataItem.answerSourceNo === 7)) ||
            ((sourceQuestion.yesAnswer || sourceQuestion.yesNoOption === 4) && (dataItem.answerSourceYes === 5 || dataItem.answerSourceYes === 7)) ? true : false;

          if ((dataItem.answerSourceNo === 8 && sourceQuestion.noAnswer) || (dataItem.answerSourceYes === 8 && sourceQuestion.yesAnswer)) {
            checkboxValue = false;
          }
          if (sourceQuestion.noAnswer || sourceQuestion.yesAnswer) {
            dataItem.isAnswered = true;
          }
        }
      }
    }
    if (dataItem.sourceQuestionId !== null) {
      if (((dataItem.answerSourceYes === 6 || dataItem.answerSourceYes === 7 || dataItem.answerSourceYes === 8) && sourceQuestion.yesAnswer) ||
        ((dataItem.answerSourceNo === 6 || dataItem.answerSourceNo === 7 || dataItem.answerSourceNo === 8) && sourceQuestion.noAnswer)) {
        disabledValue = true;
      }
    }

    return new FormControl({
      value: checkboxValue,
      disabled: disabledValue
    });
  };

  // tslint:disable-next-line: cyclomatic-complexity
  setDefaultedYesNoAnswer = (caller: string, childQuestion: any, childQuestionFormGroup: FormGroup, parentValue: boolean): void => {
    if (caller === 'yes') {
      if (childQuestion.answerSourceYes === 4) {
        childQuestionFormGroup.controls.yesAnswer.setValue(true);
        childQuestionFormGroup.controls.noAnswer.setValue(false);
        childQuestionFormGroup.controls.yesAnswer.enable();
        childQuestionFormGroup.controls.noAnswer.enable();
      } else if (childQuestion.answerSourceYes === 5) {
        childQuestionFormGroup.controls.yesAnswer.setValue(false);
        childQuestionFormGroup.controls.noAnswer.setValue(true);
        childQuestionFormGroup.controls.yesAnswer.enable();
        childQuestionFormGroup.controls.noAnswer.enable();
      } else if (childQuestion.answerSourceYes === 6) {
        childQuestionFormGroup.controls.yesAnswer.setValue(true);
        childQuestionFormGroup.controls.noAnswer.setValue(false);
        if (!!parentValue) {
            childQuestionFormGroup.controls.yesAnswer.disable();
            childQuestionFormGroup.controls.noAnswer.disable();
        } else {
            childQuestionFormGroup.controls.yesAnswer.enable();
            childQuestionFormGroup.controls.noAnswer.enable();
        }
      } else if (childQuestion.answerSourceYes === 7) {
        childQuestionFormGroup.controls.yesAnswer.setValue(false);
        childQuestionFormGroup.controls.noAnswer.setValue(true);
        if (!!parentValue) {
            childQuestionFormGroup.controls.yesAnswer.disable();
            childQuestionFormGroup.controls.noAnswer.disable();
        } else {
            childQuestionFormGroup.controls.yesAnswer.enable();
            childQuestionFormGroup.controls.noAnswer.enable();
        }
      } else if (childQuestion.answerSourceYes === 8) {
        childQuestionFormGroup.controls.yesAnswer.setValue(false);
        childQuestionFormGroup.controls.noAnswer.setValue(false);
        if (!!parentValue) {
            childQuestionFormGroup.controls.yesAnswer.disable();
            childQuestionFormGroup.controls.noAnswer.disable();
        } else {
            childQuestionFormGroup.controls.yesAnswer.enable();
            childQuestionFormGroup.controls.noAnswer.enable();
        }
      } else {
        childQuestionFormGroup.controls.yesAnswer.setValue(childQuestion.yesAnswer);
        childQuestionFormGroup.controls.noAnswer.setValue(childQuestion.noAnswer);
        childQuestionFormGroup.controls.yesAnswer.enable();
        childQuestionFormGroup.controls.noAnswer.enable();
      }
    } else if (caller === 'no') {
      if (childQuestion.answerSourceNo === 4) {
        childQuestionFormGroup.controls.noAnswer.setValue(false);
        childQuestionFormGroup.controls.yesAnswer.setValue(true);
        childQuestionFormGroup.controls.yesAnswer.enable();
        childQuestionFormGroup.controls.noAnswer.enable();
      } else if (childQuestion.answerSourceNo === 5) {
        childQuestionFormGroup.controls.noAnswer.setValue(true);
        childQuestionFormGroup.controls.yesAnswer.setValue(false);
        childQuestionFormGroup.controls.yesAnswer.enable();
        childQuestionFormGroup.controls.noAnswer.enable();
      } else if (childQuestion.answerSourceNo === 6) {
        childQuestionFormGroup.controls.yesAnswer.setValue(true);
        childQuestionFormGroup.controls.noAnswer.setValue(false);
        if (!!parentValue) {
            childQuestionFormGroup.controls.yesAnswer.disable();
            childQuestionFormGroup.controls.noAnswer.disable();
        } else {
            childQuestionFormGroup.controls.yesAnswer.enable();
            childQuestionFormGroup.controls.noAnswer.enable();
        }
      } else if (childQuestion.answerSourceNo === 7) {
        childQuestionFormGroup.controls.yesAnswer.setValue(false);
        childQuestionFormGroup.controls.noAnswer.setValue(true);
        if (!!parentValue) {
            childQuestionFormGroup.controls.yesAnswer.disable();
            childQuestionFormGroup.controls.noAnswer.disable();
        } else {
            childQuestionFormGroup.controls.yesAnswer.enable();
            childQuestionFormGroup.controls.noAnswer.enable();
        }
      } else if (childQuestion.answerSourceNo === 8) {
        childQuestionFormGroup.controls.yesAnswer.setValue(false);
        childQuestionFormGroup.controls.noAnswer.setValue(false);
        if (!!parentValue) {
            childQuestionFormGroup.controls.yesAnswer.disable();
            childQuestionFormGroup.controls.noAnswer.disable();
        } else {
            childQuestionFormGroup.controls.yesAnswer.enable();
            childQuestionFormGroup.controls.noAnswer.enable();
        }
      } else {
        childQuestionFormGroup.controls.yesAnswer.setValue(childQuestion.yesAnswer);
        childQuestionFormGroup.controls.noAnswer.setValue(childQuestion.noAnswer);
        childQuestionFormGroup.controls.yesAnswer.enable();
        childQuestionFormGroup.controls.noAnswer.enable();
      }
    }
    childQuestionFormGroup.controls.yesAnswer.markAsDirty();
    childQuestionFormGroup.controls.noAnswer.markAsDirty();
  };

  isYesNoRequired = (formGroup: FormGroup): boolean => {
    return !formGroup.controls.yesAnswer.value && !formGroup.controls.noAnswer.value && formGroup.controls.yesNoOption.value === 1;
  };

  anyChanges = (): boolean => {
    return _.find(this.grid.rowEditFormGroups, (t: any) => {
      return t.dirty === true;
    });
  };

  hideDate = (dataItem, formGroup): boolean => {
    if (formGroup.controls.yesAnswer.value && !dataItem.yesEventNumber) {
      return true;
    }
    if (formGroup.controls.noAnswer.value && !dataItem.noEventNumber) {
      return true;
    }

    return false;
  };

  private readonly setSelectedChecklistType = (id: number): void => {
    this.selectedChecklistTypeId = id;
    this.previousSelectedChecklistTypeId = id;
  };

  checkValidationAndEnableSave = (): void => {
    this.service.hasPendingChanges$.next(true);
    const isValid = this.grid.isValid();
    if ((this.anyChanges() && this.isValidData && !isValid) || (isValid && this.anyChanges())) {
      if (this.isHosted) {
        this.windowParentMessagingService.postLifeCycleMessage({
          action: 'onChange',
          target: this.hostingComponent,
          payload: {
            isDirty: true
          }
        });
      }
      this.service.hasPendingChanges$.next(true);
    } else {
      this.service.hasPendingChanges$.next(false);
    }
  };

  isValid = (): any => {
    this.isValidData = true;
    const keys = Object.keys(this.grid.rowEditFormGroups);
    keys.forEach((r) => {
      const fg = this.grid.rowEditFormGroups[r];
      fg.updateValueAndValidity();
      Object.keys(fg.controls).forEach(field => {
        if (field === 'yesNoOption' && fg.controls[field].value === 1) {
            if (fg.controls.yesAnswer.status !== 'DISABLED' && !fg.controls.yesAnswer.value && fg.controls.noAnswer.status !== 'DISABLED' && !fg.controls.noAnswer.value) {
                fg.controls.yesAnswer.setErrors({ required: true });
                fg.controls.noAnswer.setErrors({ required: true });

                fg.controls.yesAnswer.markAsDirty();
                fg.controls.yesAnswer.markAsTouched();

                fg.controls.noAnswer.markAsDirty();
                fg.controls.noAnswer.markAsTouched();
                this.isValidData = false;
            }
        } else {
          if (field === 'dateValue' && (fg.controls.noAnswer.value && fg.controls.noUpdateEventId.value && fg.controls.dateValue.value === null) || (fg.controls.yesAnswer.value && fg.controls.yesUpdateEventId.value && fg.controls.dateValue.value === null)) {
            fg.controls.dateValue.setErrors({ required: true });
            fg.controls.dateValue.markAsDirty();
            fg.controls.dateValue.markAsTouched();
            fg.controls.dateValue.setValue('');
            this.isValidData = false;
          }
          if (fg.get(field).status === 'INVALID' && field !== 'yesAnswer' && field !== 'noAnswer') {
            if (!fg.controls[field].getError('invalidentry')) {
              fg.controls[field].markAsDirty();
              fg.controls[field].markAsTouched();
              fg.controls[field].setValue('');
            }
            this.isValidData = false;
          }
        }
        this.cdr.markForCheck();
      });
      this.grid.checkChanges();
      this.cdr.detectChanges();
    });

    return this.isValidData;
  };

  getChanges = (): any => {
    const rows = [];
    const keys = Object.keys(this.grid.rowEditFormGroups);
    keys.forEach((r) => {
      if (this.grid.rowEditFormGroups[r].dirty) {
        const value = this.grid.rowEditFormGroups[r].getRawValue();
        rows.push(value);
      }
    });

    const checklistProcessedBefored = _.any(this.grid.rowEditFormGroups, (v: any) => {
      return v.value.isProcessed === 1;
    });
    const hasChargesOrLetters = _.any(rows, (v: any) => {
      return v.hasLetters || (v.hasYesCharge && v.yesAnswer) || (v.hasNoCharge && v.noAnswer);
    });
    let showRegenerationDialog = checklistProcessedBefored && (hasChargesOrLetters || this.hasGeneralDocuments) && !this.isRegeneratedPopupShown;
    if (this.cachedData.showRegenerationDialog) {
      showRegenerationDialog = this.cachedData.showRegenerationDialog && hasChargesOrLetters ? (checklistProcessedBefored && (hasChargesOrLetters || this.hasGeneralDocuments) && !this.isRegeneratedPopupShown) : false;
    }

    if (this.gridCacheddata.length > 0) {
      this.gridCacheddata.forEach((row: any) => {
        const cachedEditedQuestion = _.where(rows, {
          questionId: row.questionId
        });
        if (cachedEditedQuestion.length === 0) {
          rows.push(row);
        }
      });
    }
    rows.map((d) => {
        d.dateValue = d.dateValue ? this.dateHelper.toLocal(d.dateValue) : null;
    });
    const data = {
      checklistQuestions: {
        rows,
        checklistCriteriaKey: this.selectedCriteriaKey,
        checklistTypeId: this.selectedChecklistTypeId,
        showRegenerationDialog,
        generalDocs: this.checklistCriteriaGeneralDocs,
        isValidData: false,
        checklistProcessedBefored
      }
    };

    return data;
  };

  private readonly getColumns = (): Array<GridColumnDefinition> => {
    const columns = [
      {
        title: '',
        field: 'isProcessed',
        template: true,
        fixed: true,
        sortable: false,
        width: 50
      },
      {
        title: 'caseview.checklists.questions',
        field: 'question',
        template: true,
        fixed: true,
        sortable: false
      },
      {
        title: 'caseview.checklists.yesno',
        field: 'yesNoAnswer',
        template: true,
        sortable: false,
        width: 50
      },
      {
        title: 'caseview.checklists.date',
        field: 'dateValue',
        template: true,
        sortable: false,
        width: 135
      },
      {
        title: 'caseview.checklists.count',
        field: 'countValue',
        template: true,
        sortable: false,
        width: 50
      },
      {
        title: 'caseview.checklists.period',
        field: 'periodTypeDescription',
        template: true,
        sortable: false,
        width: 60
      },
      {
        title: 'caseview.checklists.amount',
        field: 'amountValue',
        headerClass: 'k-header-right-aligned',
        template: true,
        sortable: false,
        width: 90
      },
      {
        title: 'caseview.checklists.text',
        field: 'textValue',
        template: true,
        sortable: false
      },
      {
        title: 'caseview.checklists.selection',
        field: 'listSelection',
        template: true,
        sortable: false
      },
      {
        title: 'caseview.checklists.staff',
        field: 'staffName',
        template: true,
        sortable: false
      }
    ];

    return columns;
  };

  readonly getPaging = (): any => {
    if (this.isHosted) {
      return false;
    }

    return {
      pageSizeSetting: this.localSettings.keys.caseView.checklist.pageSize
    };
  };

  showProcessingInfo = (dataItem: any): boolean => {
    return dataItem.yesEventDesc || dataItem.noEventDesc || dataItem.yesRateDesc || dataItem.noRateDesc || dataItem.letters || dataItem.instructions;
  };

  removeOnChangeAction = () => {
    this.onChangeAction = null;
  };

  setOnChangeAction = (): void => {
    // tslint:disable-next-line: no-empty
    this.onChangeAction = () => { };
  };

  beforeSaveAction = (changedData: any) => {
    this.windowParentMessagingService.postLifeCycleMessage({
      action: 'onValidated',
      target: this.hostingComponent,
      payload: {
        isDirty: true,
        data: changedData
      }
    });
  };

  setOnHostNavigation = (payload: any, then: (val: any) => any): void => {
    if (payload.data !== null && payload.data !== undefined) {
      this.cachedData = payload.data;

      if (this.selectedChecklistTypeId !== payload.data.checklistTypeId) {
        this.selectedCriteriaKey = payload.data.checklistCriteriaKey;
        this.selectedChecklistTypeId = payload.data.checklistTypeId;
      }
      this.gridCacheddata = payload.data.rows;
    }
    this.onNavigationAction = (e: any) => {
      let changedData;
      if (this.grid.rowEditFormGroups) {
        changedData = this.getChanges();
      } else {
        changedData = {
          checklistQuestions: {
            rows: [],
            checklistCriteriaKey: this.selectedCriteriaKey,
            checklistTypeId: this.selectedChecklistTypeId,
            showRegenerationDialog: false,
            generalDocs: this.checklistCriteriaGeneralDocs,
            isValidData: true
          }
        };
      }
      if (!changedData.checklistQuestions.isValidData) {
        if (this.isValid()) {
          changedData.checklistQuestions.isValidData = true;
        }
      }
      if (changedData.checklistQuestions.showRegenerationDialog && !this.isRegeneratedPopupShown && changedData.checklistQuestions.isValidData) {
        changedData.checklistQuestions.isValidData = false;
        this.modalRef = this.modalService.openModal(RegenerateChecklistComponent, {
          animated: false,
          backdrop: 'static',
          ignoreBackdropClick: true,
          class: 'modal-lg',
          focus: true,
          initialState: changedData
        });
        this.modalRef.content.proceedData.pipe(take(1)).subscribe(() => {
          if (changedData) {
            this.isRegeneratedPopupShown = true;
            changedData.checklistQuestions.isValidData = true;
            this.beforeSaveAction(changedData);
            if (payload) {
              then({ ...payload, ...changedData });
            }
          }
        });
        this.modalRef.content.dontSave.pipe(take(1)).subscribe(() => {
          this.isRegeneratedPopupShown = false;
          changedData.checklistQuestions.isValidData = false;
          this.beforeSaveAction(changedData);
          if (payload) {
            then({ ...payload, ...changedData });
          }
        });
      } else {
        this.beforeSaveAction(changedData);
        if (payload) {
          then({ ...payload, ...changedData });
        }
      }
    };
  };
}
export class ChecklistsComponentTopic extends Topic {
  readonly key = 'caseChecklists';
  readonly title = 'caseview.checklists.header';
  readonly component = ChecklistsComponent;
  constructor(public params: ChecklistsParams) {
    super();
  }
}

export class ChecklistsParams extends TopicParam {
}