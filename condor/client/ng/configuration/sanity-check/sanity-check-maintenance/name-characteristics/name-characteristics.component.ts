import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { NameCharacteristics } from '../maintenance-model';
import { SanityCheckMaintenanceService } from '../sanity-check-maintenance.service';

@Component({
  selector: 'ipx-sanity-check-rule-name-characteristics',
  templateUrl: './name-characteristics.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SanityCheckRuleNameCharacteristicsComponent implements TopicContract, OnInit {
  formData?: any;
  appliesToOptions: Array<any>;
  topic: Topic;
  view?: any;
  entityTypeSelected: boolean;
  @ViewChild('frm', { static: true }) form: NgForm;

  private readonly typeofEntityMandatory = new BehaviorSubject<boolean>(false);
  isTypeOfEntityMandatory$ = this.typeofEntityMandatory.asObservable();

  constructor(private readonly service: SanityCheckMaintenanceService, private readonly cdr: ChangeDetectorRef) {
    this.appliesToOptions = [{
      value: 1,
      label: 'sanityCheck.configurations.localOrForeignDropdown.localClients'
    }, {
      value: 0,
      label: 'sanityCheck.configurations.localOrForeignDropdown.foreignClients'
    }];
  }

  ngOnInit(): void {
    this.topic.getDataChanges = this.getDataChanges;
    this.view = (this.topic.params?.viewData as NameCharacteristics);
    this.formData = !!this.view ? { ...this.view } : {};

    this.form.statusChanges.subscribe(() => {
      this.topic.hasChanges = this.form.dirty;
      const hasErrors = this.form.dirty && this.form.invalid;
      this.topic.setErrors(hasErrors);
      this.service.raiseStatus(this.topic.key, this.topic.hasChanges, hasErrors, this.form.valid);
    });
  }

  getDataChanges = (): any => {
    const r = {};

    r[this.topic.key] = {
      name: this.formData?.name?.key,
      nameGroup: this.formData?.nameGroup?.key,
      jurisdiction: this.formData?.jurisdiction?.code,
      category: this.formData?.category?.key,
      isLocal: this.formData?.applyTo == null ? null : this.formData?.applyTo,
      isSupplierOnly: this.formData?.typeIsSupplierOnly,
      entityType: {
        isOrganisation: this.formData?.typeIsOrganisation,
        isIndividual: this.formData?.typeIsIndividual,
        isClientOnly: this.formData?.typeIsClientOnly,
        isStaff: this.formData?.typeIsStaff
      }
    };

    return r;
  };

  tableColumnForCategory(query: any): any {
    return _.extend({}, query, {
      tableType: 'Category'
    });
  }

  usedAsChanged(): void {
    const usedAsSelected = this.formData.typeIsStaff || this.formData.typeIsClientOnly;

    this.typeofEntityMandatory.next(!!usedAsSelected);

    this.cdr.markForCheck();
  }

  nameGroupChange(): void {
    if (!!this.formData.nameGroup) {
      this.formData.name = null;
    }

    this.cdr.markForCheck();
  }

  nameChange(): void {
    if (!!this.formData.name) {
      this.formData.nameGroup = null;
    }

    this.cdr.markForCheck();
  }

  entityTypeChanged(): void {
    if (!this.formData.typeIsOrganisation) {
      this.formData.typeIsOrganisation = undefined;
    }
    if (!this.formData.typeIsIndividual) {
      this.formData.typeIsIndividual = undefined;
    }

    this.entityTypeSelected = !!this.formData.typeIsOrganisation || !!this.formData.typeIsIndividual;
    this.cdr.markForCheck();
  }
}
