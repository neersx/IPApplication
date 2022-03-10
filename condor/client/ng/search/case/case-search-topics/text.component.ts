import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { SearchOperator } from '../../common/search-operators';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';

@Component({
  selector: 'ipx-case-search-text',
  templateUrl: './text.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TextComponent extends CaseSearchTopicBaseComponent implements OnInit {
  textTypes: any;

  ngOnInit(): void {
    this.onInit();
  }

  initTopicsData = () => {
    this.textTypes = this.viewData.textTypes;
  };

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;

    return {
      typeOfMarkKey: this.casehelper.buildStringFilterFromTypeahead(formData.typeOfMarkValue, formData.typeOfMarkOperator),
      title: this.casehelper.buildStringFilter(formData.titleMarkValue, formData.titleMarkOperator, { useSoundsLike: formData.titleMarkOperator === SearchOperator.soundsLike ? 1 : 0 }),
      keyWord: this.buildKeyword(formData),
      caseTextGroup: this.buildCaseTextGroup(formData)
    };
  };

  buildCaseTextGroup(formData: any): any {
    if (this.casehelper.isFilterApplicable(formData.textTypeOperator, formData.textTypeValue)) {
      return {
        caseText: [
          {
            operator: formData.textTypeOperator,
            typeKey: formData.textType,
            text: formData.textTypeValue
          }
        ]
      };
    }
  }

  buildKeyword(formData: any): any {
    if (formData.keywordOperator === SearchOperator.equalTo || formData.keywordOperator === SearchOperator.notEqualTo) {
      return this.casehelper.buildStringFilterFromTypeahead(formData.keywordValue, formData.keywordOperator);
    }

    return this.casehelper.buildStringFilter(formData.keywordTextValue, formData.keywordOperator);
  }
}
