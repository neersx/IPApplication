import { Injectable } from '@angular/core';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import * as _ from 'underscore';
import { TabData } from '../task-planner.data';
import { TaskPlannerService } from '../task-planner.service';

@Injectable()
export class TaskPlannerSearchHelperService {
  activeTab: TabData;
  activeQueryKey: number;
  queryParams: any;
  isSearchFromSearchBuilder: boolean;

  constructor(
    private readonly taskPlannerService: TaskPlannerService,
    private readonly dateHelper: DateHelper) { }

  setSearchCriteria = (activeTab: TabData, queryParams: any, activeQueryKey: number, isSearchFromSearchBuilder: boolean) => {
    this.activeTab = activeTab;
    this.queryParams = queryParams;
    this.activeQueryKey = activeQueryKey;
    this.isSearchFromSearchBuilder = isSearchFromSearchBuilder;
  };

  getFilter = (deSelectedKeys: Array<number> = null): any => {
    this.activeTab.filter.searchRequest.belongsTo = this.activeTab.filter.searchRequest.belongsTo ? this.activeTab.filter.searchRequest.belongsTo : {};

    if (_.any(this.activeTab.names)) {
      this.activeTab.filter.searchRequest.belongsTo.nameKey = null;
      this.activeTab.filter.searchRequest.belongsTo.memberOfGroupKey = null;
      this.activeTab.filter.searchRequest.belongsTo.memberOfGroupKeys = null;
      this.activeTab.filter.searchRequest.belongsTo.nameKeys = { value: _.pluck(this.activeTab.names, 'key').join(','), operator: 0 };
    } else {
      this.activeTab.filter.searchRequest.belongsTo.nameKeys = null;
    }
    if (_.any(this.activeTab.nameGroups)) {
      this.activeTab.filter.searchRequest.belongsTo.memberOfGroupKey = null;
      this.activeTab.filter.searchRequest.belongsTo.nameKey = null;
      this.activeTab.filter.searchRequest.belongsTo.nameKeys = null;
      this.activeTab.filter.searchRequest.belongsTo.memberOfGroupKeys = { value: _.pluck(this.activeTab.nameGroups, 'key').join(','), operator: 0 };
    } else {
      this.activeTab.filter.searchRequest.belongsTo.memberOfGroupKeys = null;
    }

    if (this.isSearchFromSearchBuilder) {

      const selectedDates = this.activeTab.filter.searchRequest.dates;
      if (selectedDates && selectedDates.dateRange) {
        this.activeTab.filter.searchRequest.dates.dateRange.from = selectedDates.dateRange.from ? this.dateHelper.toLocal(selectedDates.dateRange.from) : null;
        this.activeTab.filter.searchRequest.dates.dateRange.to = selectedDates.dateRange.to ? this.dateHelper.toLocal(selectedDates.dateRange.to) : null;
      }

    } else {
      this.activeTab.filter.searchRequest.dates = this.activeTab.filter.searchRequest.dates ? this.activeTab.filter.searchRequest.dates : { dateRange: {} };
      this.activeTab.filter.searchRequest.dates.dateRange = this.activeTab.filter.searchRequest.dates.dateRange ? this.activeTab.filter.searchRequest.dates.dateRange : {};
      this.activeTab.filter.searchRequest.dates.dateRange.from = this.activeTab.savedSearch.criteria.dateFilter.from ? this.dateHelper.toLocal(this.activeTab.savedSearch.criteria.dateFilter.from) : null;
      this.activeTab.filter.searchRequest.dates.dateRange.to = this.activeTab.savedSearch.criteria.dateFilter.to ? this.dateHelper.toLocal(this.activeTab.savedSearch.criteria.dateFilter.to) : null;
      this.activeTab.filter.searchRequest.dates.dateRange.operator = this.activeTab.savedSearch.criteria.dateFilter.operator;
      this.activeTab.filter.searchRequest.dates.useDueDate = this.activeTab.savedSearch.criteria.dateFilter.useDueDate;
      this.activeTab.filter.searchRequest.dates.useReminderDate = this.activeTab.savedSearch.criteria.dateFilter.useReminderDate;
      this.activeTab.filter.searchRequest.dates.sinceLastWorkingDay = this.activeTab.savedSearch.criteria.dateFilter.sinceLastWorkingDay;
    }

    return { searchRequest: this.activeTab.filter.searchRequest, deselectedIds: deSelectedKeys };
  };

  getSearchRequestParams = (deSelectedKeys: Array<number>): any => {

    return {
      queryKey: this.activeQueryKey,
      criteria: this.getFilter(deSelectedKeys),
      params: this.queryParams,
      queryContext: queryContextKeyEnum.taskPlannerSearch,
      selectedColumns: this.activeTab.selectedColumns
    };
  };

}
