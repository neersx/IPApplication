import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import * as _ from 'underscore';
import { dataTypeEnum } from './../../../shared/component/forms/ipx-data-type/datatype-enum';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';

@Component({
  selector: 'ipx-case-search-patenttermadjustments',
  templateUrl: './patent.term.adjustments.component.html',
  styleUrls: ['./patent.term.adjustments.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class PatentTermAdjustmentsComponent extends CaseSearchTopicBaseComponent implements OnInit {
  @ViewChild('caseSearchForm', { static: true }) form: NgForm;
  dataType: any = dataTypeEnum;

  ngOnInit(): void {
    this.onInit();
  }

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;
    const request = {
      patentTermAdjustments: {}
    };
    this.addPatentAdjustmentsFilter(formData, request, 'ipOfficeAdjustment', 'suppliedPtaOperator', 'fromSuppliedPta', 'toSuppliedPta');
    this.addPatentAdjustmentsFilter(formData, request, 'calculatedAdjustment', 'determinedByUsOperator', 'fromPtaDeterminedByUs', 'toPtaDeterminedByUs');
    this.addPatentAdjustmentsFilter(formData, request, 'ipOfficeDelay', 'ipOfficeDelayOperator', 'fromIpOfficeDelay', 'toIpOfficeDelay');
    this.addPatentAdjustmentsFilter(formData, request, 'applicantDelay', 'applicantDelayOperator', 'fromApplicantDelay', 'toApplicantDelay');

    Object.assign(request.patentTermAdjustments, {
      hasDiscrepancy: formData.ptaDiscrepancies ? 1 : 0
    });

    return request;
  };

  addPatentAdjustmentsFilter = (formData, request, patentTermCriteria, operator, fromDays, toDays): void => {
    if (fromDays == null && operator == null && fromDays == null && toDays == null) {

      return;
    }

    if (formData[operator] && !_.isUndefined(formData[fromDays]) && !_.isUndefined(formData[toDays])) {
      request.patentTermAdjustments[patentTermCriteria] = {
        operator: formData[operator],
        fromDays: formData[fromDays],
        toDays: formData[toDays]
      };
    }

    return request;
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
      case 'positiveinteger':
      case 'integer':
      case 'nonnegativeinteger': {
        result = parseInt(viewValue, 10);
        break;
      }
      case 'decimal': {
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
}
