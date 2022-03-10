using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Search
{
    public interface ISearchMaintainabilityResolver
    {
        SearchMaintenability Resolve(QueryContext queryContext);
    }

    public class SearchMaintainabilityResolver : ISearchMaintainabilityResolver
    {
        static readonly Dictionary<QueryContext, ApplicationTask> CanMaintainSearchMap =
            new Dictionary<QueryContext, ApplicationTask>
            {
                {QueryContext.CaseSearch, ApplicationTask.MaintainCaseSearch},
                {QueryContext.CaseSearchExternal, ApplicationTask.MaintainCaseSearch},
                {QueryContext.NameSearch, ApplicationTask.MaintainNameSearch},
                {QueryContext.NameSearchExternal, ApplicationTask.MaintainNameSearch},
                {QueryContext.WipOverviewSearch, ApplicationTask.MaintainWipOverviewSearch},
                {QueryContext.MarketingEventSearch, ApplicationTask.MaintainMarketingEventSearch},
                {QueryContext.PriorArtSearch, ApplicationTask.MaintainPriorArtSearch},
                {QueryContext.LeadSearch, ApplicationTask.MaintainLeadSearch},
                {QueryContext.OpportunitySearch, ApplicationTask.MaintainOpportunitySearch},
                {QueryContext.CampaignSearch, ApplicationTask.MaintainCampaignSearch},
                {QueryContext.RemindersSearch, ApplicationTask.MaintainReminderSearch},
                {QueryContext.WhatsDueCalendar, ApplicationTask.MaintainWhatsDueSearchColumns},
                {QueryContext.WorkHistorySearch, ApplicationTask.MaintainWorkHistorySearch},
                {QueryContext.ToDo, ApplicationTask.MaintainToDoSearchColumns},
                {QueryContext.AdHocDateSearch, ApplicationTask.MaintainAdHocDateSearch},
                {QueryContext.ReciprocitySearch, ApplicationTask.MaintainReciprocitySearch},
                {QueryContext.ContactActivitySearch, ApplicationTask.MaintainContactActivitySearch},
                {QueryContext.CaseFeeSearchInternal, ApplicationTask.MaintainCaseFeeSearch},
                {QueryContext.CaseFeeSearchExternal, ApplicationTask.MaintainCaseFeeSearch},
                {QueryContext.CaseInstructionSearchInternal, ApplicationTask.MaintainCaseInstructionSearch},
                {QueryContext.CaseInstructionSearchExternal, ApplicationTask.MaintainCaseInstructionSearch},
                {QueryContext.ClientRequestSearchInternal, ApplicationTask.MaintainClientRequestSearch},
                {QueryContext.ClientRequestSearchExternal, ApplicationTask.MaintainClientRequestSearch},
                {QueryContext.TaskPlanner, ApplicationTask.MaintainTaskPlannerApplication}
            };

        readonly ITaskSecurityProvider _taskSecurityProvider;

        public SearchMaintainabilityResolver(ITaskSecurityProvider taskSecurityProvider)
        {
            _taskSecurityProvider = taskSecurityProvider;
        }

        public SearchMaintenability Resolve(QueryContext queryContext)
        {
            if (!CanMaintainSearchMap.TryGetValue(queryContext, out var maintainTask))
            {
                maintainTask = ApplicationTask.NotDefined;
            }

            return new SearchMaintenability(queryContext,
                                           CheckAccess(ApplicationTask.MaintainPublicSearch),
                                           CheckAccess(maintainTask, ApplicationTaskAccessLevel.Create) || CheckAccess(maintainTask, ApplicationTaskAccessLevel.Execute),
                                           CheckAccess(maintainTask, ApplicationTaskAccessLevel.Modify) || CheckAccess(maintainTask, ApplicationTaskAccessLevel.Execute),
                                           CheckAccess(maintainTask, ApplicationTaskAccessLevel.Delete) || CheckAccess(maintainTask, ApplicationTaskAccessLevel.Execute)
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

    public class SearchMaintenability
    {
        public SearchMaintenability(QueryContext queryContext,
                                   bool canMaintainPublicSearch = false,
                                   bool canCreateSavedSearch = false,
                                   bool canUpdateSavedSearch = false,
                                   bool canDeleteSavedSearch = false)
        {
            QueryContext = queryContext;
            CanMaintainPublicSearch = canMaintainPublicSearch;
            CanCreateSavedSearch = canCreateSavedSearch;
            CanUpdateSavedSearch = canUpdateSavedSearch;
            CanDeleteSavedSearch = canDeleteSavedSearch;
        }

        public QueryContext QueryContext { get; }

        public bool CanMaintainPublicSearch { get; }

        public bool CanCreateSavedSearch { get; }

        public bool CanUpdateSavedSearch { get; }

        public bool CanDeleteSavedSearch { get; }
    }
}