using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Search.Columns
{
    public interface ISearchColumnMaintainabilityResolver
    {
        SearchColumnMaintainability Resolve(QueryContext queryContext);
    }

    public class SearchColumnMaintainabilityResolver : ISearchColumnMaintainabilityResolver
    {
        static readonly Dictionary<QueryContext, ApplicationTask> CanMaintainSearchColumnMap =
            new Dictionary<QueryContext, ApplicationTask>
            {
                {QueryContext.CaseSearch, ApplicationTask.MaintainCaseSearchColumns},
                {QueryContext.CaseSearchExternal, ApplicationTask.MaintainExternalCaseSearchColumns},
                {QueryContext.NameSearch, ApplicationTask.MaintainNameSearchColumns},
                {QueryContext.NameSearchExternal, ApplicationTask.MaintainExternalNameSearchColumns},
                {QueryContext.WipOverviewSearch, ApplicationTask.MaintainWipOverviewSearchColumns},
                {QueryContext.MarketingEventSearch, ApplicationTask.MaintainMarketingEventSearchColumns},
                {QueryContext.PriorArtSearch, ApplicationTask.MaintainPriorArtSearchColumns},
                {QueryContext.LeadSearch, ApplicationTask.MaintainLeadSearchColumns},
                {QueryContext.OpportunitySearch, ApplicationTask.MaintainOpportunitySearchColumns},
                {QueryContext.CampaignSearch, ApplicationTask.MaintainCampaignSearchColumns},
                {QueryContext.WorkHistorySearch, ApplicationTask.MaintainWorkHistorySearchColumns},
                {QueryContext.CaseFeeSearchInternal, ApplicationTask.MaintainCaseFeeSearchColumns},
                {QueryContext.CaseFeeSearchExternal,ApplicationTask.MaintainExternalCaseFeeSearchColumns},
                {QueryContext.ReciprocitySearch, ApplicationTask.MaintainReciprocitySearchColumns},
                {QueryContext.CaseInstructionSearchInternal, ApplicationTask.MaintainCaseInstructionsSearchColumns},
                {QueryContext.CaseInstructionSearchExternal, ApplicationTask.MaintainExternalCaseInstructionsSearchColumns},
                {QueryContext.AdHocDateSearch, ApplicationTask.MaintainAdHocSearchColumns},
                {QueryContext.ClientRequestSearchInternal, ApplicationTask.MaintainClientRequestSearchColumns},
                {QueryContext.ClientRequestSearchExternal, ApplicationTask.MaintainExternalClientRequestSearchColumns},
                {QueryContext.RemindersSearch, ApplicationTask.MaintainStaffRemindersSearchColumns},
                {QueryContext.ToDo, ApplicationTask.MaintainToDoSearchColumns},
                {QueryContext.WhatsDueCalendar, ApplicationTask.MaintainWhatsDueSearchColumns},
                {QueryContext.ContactActivitySearch, ApplicationTask.MaintainActivitySearchColumns },
                {QueryContext.TaskPlanner, ApplicationTask.MaintainTaskPlannerSearchColumns }
            };

        readonly ITaskSecurityProvider _taskSecurityProvider;

        public SearchColumnMaintainabilityResolver(ITaskSecurityProvider taskSecurityProvider)
        {
            _taskSecurityProvider = taskSecurityProvider;
        }

        public SearchColumnMaintainability Resolve(QueryContext queryContext)
        {
            if (!CanMaintainSearchColumnMap.TryGetValue(queryContext, out var maintainTask))
            {
                maintainTask = ApplicationTask.NotDefined;
            }

            return new SearchColumnMaintainability(queryContext,
                                                   CheckAccess(maintainTask, ApplicationTaskAccessLevel.Create),
                                                   CheckAccess(maintainTask, ApplicationTaskAccessLevel.Modify),
                                                   CheckAccess(maintainTask, ApplicationTaskAccessLevel.Delete)
                                                  );
        }

        bool CheckAccess(ApplicationTask task, ApplicationTaskAccessLevel? level = null)
        {
            if (task == ApplicationTask.NotDefined)
            {
                return false;
            }

            return level == null
                ? _taskSecurityProvider.HasAccessTo(task)
                : _taskSecurityProvider.HasAccessTo(task, level.Value);
        }
    }

    public class SearchColumnMaintainability
    {
        public SearchColumnMaintainability(QueryContext queryContext,
                                           bool canCreateSearchColumn = false,
                                           bool canUpdateSearchColumn = false,
                                           bool canDeleteSearchColumn = false)
        {
            QueryContext = queryContext;
            CanCreateColumnSearch = canCreateSearchColumn;
            CanUpdateColumnSearch = canUpdateSearchColumn;
            CanDeleteColumnSearch = canDeleteSearchColumn;
        }

        public QueryContext QueryContext { get; }

        public bool CanCreateColumnSearch { get; }

        public bool CanUpdateColumnSearch { get; }

        public bool CanDeleteColumnSearch { get; }
    }
}