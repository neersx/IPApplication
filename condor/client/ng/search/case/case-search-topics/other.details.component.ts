import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FeatureDetection } from 'core/feature-detection';
import { Observable } from 'rxjs';
import { SearchHelperService } from 'search/common/search-helper.service';
import { StepsPersistenceService } from 'search/multistepsearch/steps.persistence.service';
import * as _ from 'underscore';
import { SearchOperator } from '../../common/search-operators';
import { CaseSearchTopicBaseComponent } from './case-search-topics.base.component';

@Component({
  selector: 'ipx-case-search-otherdetails',
  templateUrl: './other.details.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class OtherDetailsComponent extends CaseSearchTopicBaseComponent implements OnInit {

  entitySizes: any;
  isEntitySizeVisible: Observable<boolean>;

  constructor(public persistenceService: StepsPersistenceService,
    public casehelper: SearchHelperService, public cdRef: ChangeDetectorRef,
    private readonly featureDetection: FeatureDetection) {
    super(persistenceService, casehelper, cdRef);
  }

  ngOnInit(): void {
    this.onInit();
  }

  initTopicsData = () => {
    this.entitySizes = this.viewData.entitySizes;
    this.isEntitySizeVisible = this.featureDetection.hasSpecificRelease$(16);
  };

  onStandingInstructionChange = () => {
    if (this.formData.forInstruction) {
      this.formData.forCharacteristicOperator = SearchOperator.equalTo;
      this.formData.characteristic = null;
    }
    if (!this.formData.forInstruction) {
      this.formData.forInstructionOperator = SearchOperator.equalTo;
      this.formData.instruction = null;
    }
    this.cdRef.detectChanges();
  };

  onInheritedFromNameChange = () => {
    this.formData.forInstructionOperator = SearchOperator.equalTo;
  };

  getFilterCriteria = (savedFormData?): any => {
    const formData = savedFormData ? savedFormData : this.formData;
    const r = {
      fileLocationKeys: formData.fileLocation ? this.casehelper.buildStringFilter(_.pluck(formData.fileLocation, 'key').join(','), formData.fileLocationOperator) : null,
      fileLocationBayNo: this.casehelper.buildStringFilter(formData.bayNo, formData.bayNoOperator),
      purchaseOrderNo: this.casehelper.buildStringFilter(formData.purchaseOrderNo, formData.purchaseOrderNoOperator),
      entitySize: this.buildEntitySizeFilter(formData.entitySize, formData.entitySizeOperator)
    };

    if (formData.policingIncomplete) {
      Object.assign(r, {
        hasIncompletePolicing: this.casehelper.buildStringFilter(1, SearchOperator.equalTo)
      });
    }

    if (formData.globalNameChangeIncomplete) {
      Object.assign(r, {
        hasIncompleteNameChange: this.casehelper.buildStringFilter(1, SearchOperator.equalTo)
      });
    }

    if (formData.letters
      || formData.charges) {
      Object.assign(r, {
        queueFlags: {
          hasLettersOnQueue: this.buildLettersQueueFlag(formData),
          hasChargesOnQueue: this.buildChargesQueueFlags(formData)
        }
      });
    }

    if (formData.forInstruction) {
      Object.assign(r, {
        instructionKey: formData.instruction ? this.casehelper.buildStringFilter(formData.instruction.id, formData.forInstructionOperator) : null
      });
    }

    Object.assign(r, {
      standingInstructions: {
        includeInherited: formData.includeInherited ? 1 : 0,
        characteristicFlag: this.buildCharacteristicFlag(formData)
      }
    });

    return r;
  };

  buildCharacteristicFlag = (formData) => {
    if (!formData.forInstruction) {
      return formData.characteristic ? this.casehelper.buildStringFilter(formData.characteristic.id, formData.forCharacteristicOperator) : null;
    }

    return null;
  };

  buildLettersQueueFlag = (formData) => {
    if (formData.letters) {
      return this.casehelper.buildStringFilter(1, SearchOperator.equalTo);
    }

    return null;
  };

  buildChargesQueueFlags = (formData) => {
    if (formData.charges) {
      return this.casehelper.buildStringFilter(1, SearchOperator.equalTo);
    }

    return null;
  };

  buildEntitySizeFilter = (entitySize, operator) => {
    if (!entitySize && operator !== SearchOperator.exists && operator !== SearchOperator.notExists) {
      return null;
    }
    const filter = {
      operator,
      value: null
    };
    if (operator === SearchOperator.equalTo || operator === SearchOperator.notEqualTo) {
      filter.value = entitySize.key;
    }

    return filter;
  };

}
