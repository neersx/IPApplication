import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { Hotkey } from 'angular2-hotkeys';
import { KeyBoardShortCutService } from 'core/keyboardshortcut.service';
import { KnownNameTypes } from 'names/knownnametypes';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import * as _ from 'underscore';
import { SearchOperator } from '../../common/search-operators';
import { NameFilteredPicklistScope } from '../case-search-topics/name-filtered-picklist-scope';
import { DueDateFilterService } from './due-date-filter.service';
import {
  DueDateCallbackParams,
  DueDateFormData,
  PeriodTypes
} from './due-date.model';

@Component({
  selector: 'ipx-due-dateform',
  templateUrl: './due-date.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class DueDateComponent implements OnInit {
  @Input() existingFormData: any;
  @Input() hasDueDateColumn: boolean;
  @Input() importanceLevelOptions: any;
  @Input() hasAllDateColumn: boolean;
  @ViewChild('dueDateForm', { static: true }) form: NgForm;
  modalRef: BsModalRef;
  dataType: any = dataTypeEnum;
  warningMessage: string;
  @Output() readonly searchRecord: EventEmitter<any> = new EventEmitter();
  periodTypes: any;
  formData: DueDateFormData;
  filterCriteria: any;
  callbackParams: DueDateCallbackParams;
  staffPickListExternalScope: NameFilteredPicklistScope;
  searchOperator: any = SearchOperator;
  nameTypeQuery: Function;

  constructor(
    bsModalRef: BsModalRef,
    public filterService: DueDateFilterService,
    public knownNameTypes: KnownNameTypes,
    private readonly translate: TranslateService,
    private readonly keyBoardShortCutService: KeyBoardShortCutService
  ) {
    this.modalRef = bsModalRef;
    this.periodTypes = this.filterService.getPeriodTypes();
    this.nameTypeQuery = this.extendNameTypeQuery.bind(this);
    this.initShortcuts();
  }

  initShortcuts = () => {
    const hotkeys = [
      new Hotkey(
        'enter',
        (event, combo): boolean => {
          this.search();

          return true;
        }, null, 'shortcuts.search', undefined, false)
    ];
    this.keyBoardShortCutService.add(hotkeys);
  };

  ngOnInit(): void {
    if (this.existingFormData) {
      this.formData = this.existingFormData;
      this.showHideRangePeriod(this.formData.rangeType, true);
        this.formData.startDate = this.formData.startDate ? new Date(this.formData.startDate) : null;
        this.formData.endDate = this.formData.endDate ? new Date(this.formData.endDate) : null;
    } else {
      this.initFormData();
    }
    this.setMessage();
  }

  setMessage(): void {

    if (this.hasDueDateColumn && !this.hasAllDateColumn) {
      this.warningMessage = this.translate.instant('dueDate.dueDateOnlyMessage');
    } else if (this.hasDueDateColumn && this.hasAllDateColumn) {
      this.warningMessage = this.translate.instant('dueDate.dueDateAndAllDateMessage');
    } else if (!this.hasDueDateColumn && this.hasAllDateColumn) {
      this.warningMessage = this.translate.instant('dueDate.allDateOnlyMessage');
    } else if (!this.hasDueDateColumn && !this.hasAllDateColumn) {
      this.warningMessage = this.translate.instant('dueDate.neitherDueDateNorAllDateMessage');
    }
  }
  init = (): void => {
    this.initFormData();
    this.filterCriteria = {};
  };

  initFormData = () => {
    this.formData = {
      event: true,
      adhoc: false,
      searchByRemindDate: false,
      isRange: true,
      isPeriod: false,
      rangeType: 0,
      searchByDate: true,
      dueDatesOperator: SearchOperator.between,
      periodType: PeriodTypes.days,
      importanceLevelOperator: SearchOperator.between,
      importanceLevelFrom: null,
      importanceLevelTo: null,
      eventOperator: SearchOperator.equalTo,
      eventValue: null,
      eventCategoryOperator: SearchOperator.equalTo,
      eventCategoryValue: null,
      actionOperator: SearchOperator.equalTo,
      actionValue: null,
      isRenevals: true,
      isNonRenevals: true,
      isClosedActions: false,
      isAnyName: false,
      isStaff: false,
      isSignatory: false,
      nameTypeOperator: SearchOperator.equalTo,
      nameTypeValue: null,
      nameOperator: SearchOperator.equalTo,
      nameValue: null,
      nameGroupOperator: SearchOperator.equalTo,
      nameGroupValue: null,
      staffClassificationOperator: SearchOperator.equalTo,
      staffClassificationValue: null
    };

    this.staffPickListExternalScope = new NameFilteredPicklistScope(
      this.knownNameTypes.StaffMember,
      this.translate.instant('picklist.staff')
    );
  };

  onClose(): void {
    this.emitSearchParams(true);
  }

  search = (): void => {
    this.emitSearchParams(false);
  };

  emitSearchParams = (isModalClosed: Boolean): void => {
    this.callbackParams = {
      formData: this.formData,
      filterCriteria: this.filterService.prepareFilter(this.formData),
      isModalClosed
    };
    this.searchRecord.emit(this.callbackParams);
  };

  extendNameTypeQuery(query): any {
    const extended = _.extend({}, query, {
      usedByStaff: true
    });

    return extended;
  }

  showHideRangePeriod = (value: Number, isPageLoad: boolean): void => {
    if (!isPageLoad) {
      this.formData.dueDatesOperator = SearchOperator.between;
    }

    if (value === 0) {
      this.formData.isRange = true;
      this.formData.isPeriod = false;
      this.formData.fromPeriod = null;
      this.formData.toPeriod = null;
      if (!isPageLoad) {
        this.formData.periodType = PeriodTypes.days;
      }
    } else if (value === 1) {
      this.formData.isRange = false;
      this.formData.isPeriod = true;
      this.formData.startDate = null;
      this.formData.endDate = null;
    }
  };

  compareFromandToDays = (fromDays, toDays, control, datatype): any => {
    if (fromDays && toDays) {
      const fromDaysCon = this.parse(fromDays, datatype);
      const toDaysCon = this.parse(toDays, datatype);
      if ((fromDaysCon > toDaysCon)) {
        this.form.controls[control].markAsTouched();
        this.form.controls[control].setErrors({ 'caseSearch.patentTermAdjustments.errorMessage': true });
      } else {
        this.form.controls[control].setErrors(null);
      }

    }
  };

  parse(viewValue: any, datatype: string): any {
    let result: any;
    switch (datatype) {
      case dataTypeEnum.positiveinteger:
      case dataTypeEnum.integer:
      case dataTypeEnum.nonnegativeinteger: {
        result = parseInt(viewValue, 10);
        break;
      }
      case dataTypeEnum.decimal: {
        result = parseFloat(viewValue);
        break;
      }
      default: {
        result = viewValue;
        break;
      }
    }

    return result;
  }

  manageRenewals(event): void {
    if (!event && !this.formData.isRenevals) {
      this.formData.isRenevals = true;
    } else if (!event && !this.formData.isNonRenevals) {
      this.formData.isNonRenevals = true;
    }
  }
}
