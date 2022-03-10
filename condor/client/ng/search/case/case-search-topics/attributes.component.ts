import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { SearchOperator } from '../../common/search-operators';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';

@Component({
  selector: 'ipx-case-search-attributes',
  templateUrl: './attributes.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AttributesComponent extends CaseSearchTopicBaseComponent implements OnInit {
  attributes: any;

  ngOnInit(): void {
    this.onInit();
  }

  initTopicsData = () => {
    this.attributes = this.viewData.attributes;
  };

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;
    const attributes = [];

    this.addAttributeFilter(attributes, formData.attribute1.attributeType, formData.attribute1.attributeValue, formData.attribute1.attributeOperator);
    this.addAttributeFilter(attributes, formData.attribute2.attributeType, formData.attribute2.attributeValue, formData.attribute2.attributeOperator);
    this.addAttributeFilter(attributes, formData.attribute3.attributeType, formData.attribute3.attributeValue, formData.attribute3.attributeOperator);
    const request = {
      attributeGroup: {
        booleanOr: formData.booleanAndOr,
        attribute: attributes
      }
    };

    return request;
  };

  extendAttributePicklist1 = (query: any): any => {
    return {
      ...query,
      tableType: !this.formData.attribute1.attributeType ? '' : this.formData.attribute1.attributeType.key
    };
  };

  extendAttributePicklist2 = (query: any): any => {
    return {
      ...query,
      tableType: !this.formData.attribute2.attributeType ? '' : this.formData.attribute2.attributeType.key
    };
  };

  extendAttributePicklist3 = (query: any): any => {
    return {
      ...query,
      tableType: !this.formData.attribute3.attributeType ? '' : this.formData.attribute3.attributeType.key
    };
  };

  onAttributeChanged = (attribute: any) => {
    this.formData[attribute].attributeValue = null;
    if (this.formData[attribute].attributeType === null || this.formData[attribute].attributeType === '') {
      this.formData[attribute].attributeOperator = SearchOperator.equalTo;
    }
    this.cdRef.detectChanges();
  };

  addAttributeFilter(attributes, attributeType, attributeValue, operator): void {
    if (!attributeType || (!attributeValue && operator !== SearchOperator.exists && operator !== SearchOperator.notExists)) {
      return;
    }
    const attrFilter = {
      operator,
      typeKey: attributeType.key,
      attributeKey: null
    };
    if (operator === SearchOperator.equalTo || operator === SearchOperator.notEqualTo) {
      attrFilter.attributeKey = attributeValue.key;
    }
    attributes.push(attrFilter);
  }

  discard = (): void => {
    this.formData = {
      attribute1: {
        attributeOperator: SearchOperator.equalTo
      },
      attribute2: {
        attributeOperator: SearchOperator.equalTo
      },
      attribute3: {
        attributeOperator: SearchOperator.equalTo
      },
      booleanAndOr: 0
    };
    this.cdRef.detectChanges();
  };
}
