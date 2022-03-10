import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RightBarNavService } from 'rightbarnav/rightbarnav.service';
import { TaskPlannerPreferenceModel, UserPreferenceViewData } from 'search/task-planner/task-planner.data';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';

@Component({
  selector: 'task-Planner-Preferences',
  templateUrl: './task-planner-preferences.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TaskPlannerPreferencesComponent implements OnInit {

  formData: TaskPlannerPreferenceModel;
  areAllLockedTab = false;
  @Input() viewData: UserPreferenceViewData;
  @ViewChild('userPreferencesForm', { static: true }) form: NgForm;

  constructor(readonly cdref: ChangeDetectorRef, readonly taskPlannerService: TaskPlannerService, readonly rightBarNavService: RightBarNavService, readonly notificationService: NotificationService, private readonly ipxNotificationService: IpxNotificationService) {
    this.formData = new TaskPlannerPreferenceModel();
  }
  ngOnInit(): void {
    this.areAllLockedTab = this.viewData.defaultTabsData.filter(x => x.isLocked).length === this.viewData.defaultTabsData.length;
    this.setFormData();
  }

  toggle(event): void {
    this.formData.autoRefreshGrid = event;
  }

  close(): void {
    this.rightBarNavService.onCloseRightBarNav$.next(true);
  }

  canSave(): Boolean {
    return this.form.dirty && this.form.valid;
  }

  resetToDefault(): void {
    this.formData.tabs = [];
    this.viewData.defaultTabsData.forEach(tab => {
      this.formData.tabs.push({ ...tab });
    });
    this.form.form.markAsDirty();
    this.form.form.controls.tabSavedSearch1.markAsDirty();
  }

  tackByFn = (index: number): number => index;

  submit = (): void => {
    this.taskPlannerService.setUserPreference(this.formData).subscribe(() => {
      this.taskPlannerService.autoRefreshGrid = this.formData.autoRefreshGrid;
      if (this.viewData.maintainTaskPlannerSearch && (this.form.form.controls.tabSavedSearch1.dirty || this.form.form.controls.tabSavedSearch2.dirty || this.form.form.controls.tabSavedSearch3.dirty)) {
        const modal = this.ipxNotificationService.openConfirmationModal('taskPlanner.contextMenu.pcPromptTitle', 'taskPlanner.contextMenu.pcSuccessMessageForTabs', 'Proceed', 'Cancel');
        modal.content.confirmed$.subscribe(() => {
          window.location.reload();
        });
      } else {
        this.notificationService.info({ title: 'taskPlanner.contextMenu.pcPromptTitle', message: 'taskPlanner.contextMenu.pcSuccessMessage' });
      }
      this.form.form.markAsPristine();
      this.cdref.markForCheck();
    });
  };

  private setFormData(): void {
    this.formData.autoRefreshGrid = this.viewData.preferenceData.autoRefreshGrid;
    this.formData.tabs = [];
    this.viewData.preferenceData.tabs.forEach(tab => {
      this.formData.tabs.push({ ...tab });
    });
    this.cdref.markForCheck();
  }

}
