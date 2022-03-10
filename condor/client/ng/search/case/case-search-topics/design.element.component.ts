import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import * as _ from 'underscore';
import { SearchOperator } from '../../common/search-operators';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';

@Component({
  selector: 'ipx-case-search-designelement',
  templateUrl: './design.element.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DesignElementComponent extends CaseSearchTopicBaseComponent implements OnInit {
  formData: any = {};
  dataType: any = dataTypeEnum;

   ngOnInit(): void {
    this.onInit();
  }

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;
    const textFields = ['firmElement', 'clientElement',
      'officialElement', 'registrationNo',
      'typeface', 'elementDescription'];

    let request = null;

    const filteredValues = _.chain(textFields)
      .filter((element) => {
        return formData[element] && formData[element] !== '';
      }).value();

    if (!_.any(filteredValues) && !formData.isRenew) {
      return null;
    }
    request = {
      designElements: {
        isRenew: formData.isRenew ? this.buildStringFilter(1, SearchOperator.equalTo) : null
      }
    };
    _.each(filteredValues, (element) => {
      request.designElements[element] = this.buildStringFilter(formData[element], formData[element + 'Operator']);
    });

    return request;
  };

  buildStringFilter = (value, operator?): any => {
    return {
      value,
      operator
    };
  };
}
