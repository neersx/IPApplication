import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { StepsPersistenceService } from 'search/multistepsearch/steps.persistence.service';
import * as _ from 'underscore';
import { SearchHelperService } from '../../common/search-helper.service';
import { SearchOperator } from '../../common/search-operators';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';

@Component({
  selector: 'ipx-case-search-references',
  templateUrl: './references.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ReferencesComponent extends CaseSearchTopicBaseComponent implements OnInit {
  numberTypes: any;
  nameTypes: any;
  caseNameType: any;

  constructor(public persistenceService: StepsPersistenceService,
    public casehelper: SearchHelperService, private readonly tranlate: TranslateService,
    public cdRef: ChangeDetectorRef) {
    super(persistenceService, casehelper, cdRef);
  }

  ngOnInit(): void {
    this.onInit();
  }

  initTopicsData = () => {
    this.numberTypes = this.viewData.numberTypes;
    this.nameTypes = this.viewData.nameTypes;
    this.updateNameFilterLabel();
  };

  loadFormData = (formData): void => {
    this.formData = formData;
    Object.assign(this.topic, { formData });
    this.updateNameFilterLabel();
    this.cdRef.detectChanges();
  };

  updateNameFilterLabel = (): void => {
    const nameTypeKey = this.formData.caseNameReferenceType;
    if (nameTypeKey) {
      const nameType = _.find(this.nameTypes, (item: any) => {
        return item.key === nameTypeKey;
      });
      if (nameType != null) {
        this.caseNameType = {
          name: nameType.value
        };

        return;
      }
    }
    this.caseNameType = {
      name: this.tranlate.instant('caseSearch.topics.references.caseNameReferenceDefault')
    };
  };

  officialNumberUpdated = () => {
    if (!this.formData.officialNumber) {
      this.formData.searchNumbersOnly = false;
      this.formData.searchRelatedCases = false;
    }
    this.cdRef.detectChanges();
  };

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;
    const r = {};
    if (this.isExternal) {
      if (
        this.casehelper.isFilterApplicable(
          formData.yourReferenceOperator,
          formData.yourReference
        )
      ) {
        Object.assign(r, {
          clientReference: this.casehelper.buildStringFilter(
            formData.yourReference,
            formData.yourReferenceOperator
          )
        });
      }
    }
    if (
      formData.caseReferenceOperator === SearchOperator.equalTo
      || formData.caseReferenceOperator === SearchOperator.notEqualTo
    ) {
      Object.assign(r, {
        caseKeys: this.casehelper.buildStringFilter(
          _.pluck(formData.caseKeys, 'key').join(','),
          formData.caseReferenceOperator
        )
      });
    } else {
      Object.assign(r, {
        caseReference: this.casehelper.buildStringFilter(
          formData.caseReference,
          formData.caseReferenceOperator
        )
      });
    }

    Object.assign(r, {
      officialNumber: this.buildOfficialNumberFilter(formData),
      caseNameReference: this.buildCaseNameReferenceFilter(formData),
      familyKeyList: this.buildFamilyKeyList(formData),
      familyKey: this.casehelper.buildStringFilter(
        _.pluck(formData.family, 'key').join(','),
        formData.familyOperator
      ),
      caseList: this.buildCaseListFilter(formData)
    });

    return r;
  };

  buildFamilyKeyList = (formData): any => {
    if (this.casehelper.isFilterApplicable(formData.familyOperator, _.pluck(formData.family, 'key').join(','))) {
      const familyKeys = _.map(_.pluck(formData.family, 'key'), (f) => {
        return { value: f };
      });

      return {
        operator: formData.familyOperator,
        familyKey: familyKeys
      };
    }

    return null;
  };

  buildOfficialNumberFilter = (formData) => {
    return this.casehelper.isFilterApplicable(
      formData.officialNumberOperator,
      formData.officialNumber
    )
      ? {
        number: {
          value: formData.officialNumber,
          useNumericSearch: formData.searchNumbersOnly ? 1 : 0
        },
        operator: formData.officialNumberOperator,
        typeKey: formData.officialNumberType,
        useRelatedCase:
          formData.officialNumberOperator !== SearchOperator.exists
            && formData.officialNumberOperator !== SearchOperator.notExists
            ? (formData.searchRelatedCases ? 1 : 0)
            : 0,
        useCurrent: 0
      }
      : {};
  };

  buildCaseNameReferenceFilter = (formData: any) => {
    return this.casehelper.isFilterApplicable(
      formData.caseNameReferenceOperator,
      formData.caseNameReference) ? {
        typeKey: formData.caseNameReferenceType,
        referenceNo: formData.caseNameReference,
        operator: formData.caseNameReferenceOperator
      } : {};
  };

  buildCaseListFilter = (formData: any) => {
    const caseListKey = formData.caseList ? formData.caseList.key : null;
    if (
      !this.casehelper.isFilterApplicable(formData.caseListOperator, caseListKey)
      && !formData.isPrimeCasesOnly
    ) {
      return null;
    }

    return {
      isPrimeCasesOnly: formData.isPrimeCasesOnly ? 1 : 0,
      caseListKey: this.casehelper.buildStringFilter(
        caseListKey,
        formData.caseListOperator
      )
    };
  };
}
