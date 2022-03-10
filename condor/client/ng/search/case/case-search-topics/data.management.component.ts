import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { SearchOperator } from '../../common/search-operators';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';
import { NameFilteredPicklistScope } from './name-filtered-picklist-scope';

@Component({
  selector: 'ipx-case-search-datamanagement',
  templateUrl: './data.management.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DataManagementComponent extends CaseSearchTopicBaseComponent implements OnInit {
  sentToCpaBatchNo: any;
  dataSourceExternalScope: NameFilteredPicklistScope;

  ngOnInit(): void {
    this.onInit();
    this.dataSourceExternalScope = new NameFilteredPicklistScope();
    this.sentToCpaBatchNo = this.viewData.sentToCpaBatchNo;
  }

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;

    return {
        edeBatchIdentifier: this.casehelper.buildStringFilter(formData.batchIdentifier, SearchOperator.equalTo),
        cpaSentBatchNo: this.casehelper.buildStringFilter(formData.sentToCPA, SearchOperator.equalTo),
        edeDataSourceNameNo: formData.dataSource ? this.casehelper.buildStringFilter(formData.dataSource.key, SearchOperator.equalTo) : null
    };
  };
}
