using System.Collections.Generic;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Configuration.Rules.Checklists
{
    public static class ChecklistConfigurationSearchCommand
    {
        public const string Command = "ipw_ChecklistConfigurationSearch";

        public static IEnumerable<ChecklistConfigurationItem> ChecklistConfigurationSearch(this IDbContext dbContext, int userId, string culture, SearchCriteria c)
        {
            return DbContextHelpers.ExecuteSqlQuery<ChecklistConfigurationItem>(dbContext,
                                                                                Command,
                                                                                userId,
                                                                                culture,
                                                                                CriteriaPurposeCodes.CheckList,
                                                                                c.Office,
                                                                                c.Checklist,
                                                                                c.CaseType,
                                                                                c.Jurisdiction,
                                                                                c.PropertyType,
                                                                                c.CaseCategory,
                                                                                c.SubType,
                                                                                c.Basis,
                                                                                c.Profile,
                                                                                c.ApplyTo == ClientFilterOptions.Na || string.IsNullOrWhiteSpace(c.ApplyTo) ? null : c.ApplyTo == ClientFilterOptions.LocalClients,
                                                                                c.MatchType == CriteriaMatchOptions.ExactMatch,
                                                                                c.IncludeProtectedCriteria ? null : true,
                                                                                null,
                                                                                c.Question
                                                                               );
        }

        public static IEnumerable<ChecklistConfigurationItem> ChecklistConfigurationSearchByIds(this IDbContext dbContext, int userId, string culture, int[] ids)
        {
            return DbContextHelpers.ExecuteSqlQuery<ChecklistConfigurationItem>(dbContext,
                                                                                Command,
                                                                                userId,
                                                                                culture,
                                                                                CriteriaPurposeCodes.CheckList,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                string.Join(",", ids)
                                                                               );
        }
    }

    public class ChecklistConfigurationItem : CaseScreenDesignerListItem
    { 
        public short? ChecklistTypeCode { get; set; }
        public string ChecklistTypeDescription { get; set; }
    }
}
