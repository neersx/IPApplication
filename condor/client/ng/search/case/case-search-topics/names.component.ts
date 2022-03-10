import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { KnownNameTypes } from 'names/knownnametypes';
import { StepsPersistenceService } from 'search/multistepsearch/steps.persistence.service';
import * as _ from 'underscore';
import { SearchHelperService } from '../../common/search-helper.service';
import { SearchOperator } from '../../common/search-operators';
import { CaseSearchService } from '../case-search.service';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';
import { NameFilteredPicklistScope } from './name-filtered-picklist-scope';

@Component({
  selector: 'ipx-case-search-names',
  templateUrl: './names.component.html',
  styleUrls: ['./names.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class NamesComponent extends CaseSearchTopicBaseComponent implements OnInit {
  formData: any = {};
  caseNameType: any;
  nameTypes: any;
  nameVariants: any;

  instructorPickListExternalScope: NameFilteredPicklistScope;
  ownerPickListExternalScope: NameFilteredPicklistScope;
  agentPickListExternalScope: NameFilteredPicklistScope;
  staffPickListExternalScope: NameFilteredPicklistScope;
  signatoryPickListExternalScope: NameFilteredPicklistScope;
  namePickListExternalScope: NameFilteredPicklistScope;

  constructor(private readonly translate: TranslateService,
    private readonly service: CaseSearchService,
    public knownNameTypes: KnownNameTypes,
    public persistenceService: StepsPersistenceService,
    public casehelper: SearchHelperService,
    public cdRef: ChangeDetectorRef) {
    super(persistenceService, casehelper, cdRef);
  }

  ngOnInit(): void {
    this.onInit();
  }

  initTopicsData = () => {
    this.nameTypes = this.viewData.nameTypes;

    this.staffPickListExternalScope = new NameFilteredPicklistScope(
      this.knownNameTypes.StaffMember,
      this.translate.instant('picklist.staff'),
      this.viewData.showCeasedNames
    );
    this.instructorPickListExternalScope = new NameFilteredPicklistScope(
      this.knownNameTypes.Instructor,
      this.translate.instant('picklist.instructor'),
      this.viewData.showCeasedNames
    );
    this.ownerPickListExternalScope = new NameFilteredPicklistScope(
      this.knownNameTypes.Owner,
      this.translate.instant('picklist.owner'),
      this.viewData.showCeasedNames
    );
    this.agentPickListExternalScope = new NameFilteredPicklistScope(
      this.knownNameTypes.Agent,
      this.translate.instant('picklist.agent'),
      this.viewData.showCeasedNames
    );
    this.signatoryPickListExternalScope = new NameFilteredPicklistScope(
      this.knownNameTypes.Signatory,
      this.translate.instant('picklist.signatory'),
      this.viewData.showCeasedNames
    );
    this.namePickListExternalScope = new NameFilteredPicklistScope();
  };

  clientNameTypeShown = (nameTypeCode: any) => {
    if (!this.isExternal) {
      return true;
    }

    const clientNameTypesShown = _.pluck(this.nameTypes, 'key');
    const contains = _.contains(clientNameTypesShown, nameTypeCode);

    return contains;
  };

  nameChange(): any {
    const names = this.formData.names;
    if (
      names &&
      names.length === 1 &&
      (this.formData.namesOperator === SearchOperator.equalTo ||
        this.formData.namesOperator === SearchOperator.notEqualTo)
    ) {
      const nameId = parseInt(names[0].key, 10);
      if (nameId) {
        this.service.getNameVariants(names[0].key).then(val => {
          this.nameVariants = val.result;
          this.cdRef.detectChanges();
        });
      }
    } else {
      this.nameVariants = null;
      this.formData.nameVariant = null;
    }
    this.cdRef.detectChanges();
  }

  namesTypeChanged(): any {
    if (this.formData.namesType != null) {
      this.namePickListExternalScope.filterNameType = this.formData.namesType;
      const nameType = _.find(this.nameTypes, (n: any) => {
        return n.key === this.formData.namesType;
      });
      this.namePickListExternalScope.nameTypeDescription = nameType ?
        nameType.value :
        null;
    } else {
      this.namePickListExternalScope.filterNameType = null;
      this.namePickListExternalScope.nameTypeDescription = null;
    }
    this.cdRef.detectChanges();
  }

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;
    const caseNames = [];

    this.addNameFilter(
      caseNames,
      formData.instructor,
      formData.instructorValue,
      this.knownNameTypes.Instructor,
      formData.instructorOperator
    );
    this.addNameFilter(
      caseNames,
      formData.owner,
      formData.ownerValue,
      this.knownNameTypes.Owner,
      formData.ownerOperator
    );
    this.addNameFilter(
      caseNames,
      formData.agent,
      formData.agentValue,
      this.knownNameTypes.Agent,
      formData.agentOperator
    );
    this.addNameFilter(
      caseNames,
      formData.staff,
      null,
      this.knownNameTypes.StaffMember,
      formData.staffOperator,
      formData.isStaffMyself ?
        {
          isCurrentUser: formData.isStaffMyself ? 1 : 0
        } :
        null
    );

    this.addNameFilter(
      caseNames,
      formData.signatory,
      null,
      this.knownNameTypes.Signatory,
      formData.signatoryOperator,
      formData.isSignatoryMyself ?
        {
          isCurrentUser: formData.isSignatoryMyself ? 1 : 0
        } :
        null
    );

    this.addNameFilter(
      caseNames,
      formData.names,
      formData.namesValue,
      formData.namesType,
      formData.namesOperator,
      formData.searchAttentionName ?
        {
          useAttentionName: formData.searchAttentionName ? 1 : 0
        } :
        null,
      formData.nameVariant ? formData.nameVariant.key : null
    );

    const request = {
      nameRelationships: this.buildNameRelationships(formData),
      inheritedName: this.buildInheritedName(formData),
      caseNameGroup: {
        caseName: caseNames
      }
    };
    if (formData.includeCaseValue) {
      const caseNameFromCase = {
        caseKey: formData.includeCaseValue.key,
        nameTypeKey: formData.isOtherCasesValue
      };
      Object.assign(request, {
        CaseNameFromCase: caseNameFromCase
      });
    }

    return request;
  };

  addNameFilter(
    caseNames,
    names,
    freeTextName,
    nameType,
    operator,
    otherNameAttributes = null,
    nameVariantKeys = null
  ): any {
    if (
      names == null &&
      freeTextName == null &&
      operator !== SearchOperator.exists &&
      operator !== SearchOperator.notExists &&
      otherNameAttributes == null
    ) {
      return;
    }

    const n = {
      operator,
      typeKey: nameType,
      nameKeys: {
        value: null
      },
      name: null,
      nameVariantKeys: null
    };

    let nameKeys;
    if (operator === SearchOperator.equalTo || operator === SearchOperator.notEqualTo) {
      nameKeys = _.pluck(names, 'key').join(',');
      if (nameKeys === '' && !(nameVariantKeys || otherNameAttributes)) {
        return;
      }
      n.nameKeys.value = nameKeys;
    } else if (operator !== SearchOperator.exists && operator !== SearchOperator.notExists) {
      n.name = freeTextName;
    }

    if (otherNameAttributes) {
      Object.assign(n.nameKeys, otherNameAttributes);
    }

    if (nameVariantKeys) {
      n.nameVariantKeys = nameVariantKeys;
    }
    caseNames.push(n);

    return n;
  }

  buildNameRelationships(formData: any): any {
    return {
      operator: SearchOperator.equalTo,
      nameTypes: this.casehelper.getKeysFromTypeahead(formData.nameTypeValue),
      relationships: this.casehelper.getKeysFromTypeahead(formData.relationship)
    };
  }

  buildInheritedName(formData: any): any {
    return {
      nameTypeKey: this.casehelper.buildStringFilterFromTypeahead(
        formData.inheritedNameType,
        formData.inheritedNameTypeOperator
      ),
      parentNameKey: this.casehelper.buildStringFilter(
        formData.parentName ? formData.parentName.key : null,
        formData.parentNameOperator
      ),
      defaultRelationshipKey: this.casehelper.buildStringFilterFromTypeahead(
        formData.defaultRelationship,
        formData.defaultRelationshipOperator
      )
    };
  }

  applyIsMyself = (type: string): any => {
    if (type === 'staff') {
      this.formData.staff = null;
    }

    if (type === 'signatory') {
      this.formData.signatory = null;
    }
  };
}
