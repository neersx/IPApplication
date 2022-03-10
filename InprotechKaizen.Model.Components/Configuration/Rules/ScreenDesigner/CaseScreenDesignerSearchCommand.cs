using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner
{
    public static class CaseScreenDesignerSearchCommand
    {
        public const string Command = "ipw_CaseScreenDesignerSearch";

        public static IEnumerable<CaseScreenDesignerListItem> CaseScreenDesignerSearch(
            this IDbContext dbContext,
            int userId,
            string culture,
            SearchCriteria c)
        {
            return DbContextHelpers.ExecuteSqlQuery<CaseScreenDesignerListItem>(
                                                                                dbContext,
                                                                                Command,
                                                                                userId,
                                                                                culture,
                                                                                CriteriaPurposeCodes.WindowControl, //  @psPurposeCode
                                                                                c.Office, //  @pnCaseOfficeID
                                                                                c.CaseProgram, //@psProgramID
                                                                                c.CaseType, //  @psCaseType
                                                                                c.Jurisdiction, //  @psCountryCode
                                                                                c.PropertyType, //  @psPropertyType
                                                                                c.CaseCategory, //  @psCaseCategory
                                                                                c.SubType, //  @psSubType
                                                                                c.Basis, //  @psBasis
                                                                                c.Profile, // @pnProfileKey
                                                                                c.IncludeCriteriaNotInUse ? (bool?)null : true, //  @pnRuleInUse
                                                                                c.MatchType == CriteriaMatchOptions.ExactMatch, // @pbExactMatch
                                                                                c.IncludeProtectedCriteria ? (bool?)null : true, //  @pbUserDefinedRule
                                                                                null // @psCriteriaNumbers
                                                                               );
        }

        public static IEnumerable<CaseScreenDesignerListItem> CaseScreenDesignerSearchByIds(
          this IDbContext dbContext,
          int userId,
          string culture,
          int[] ids)
        {
            return DbContextHelpers.ExecuteSqlQuery<CaseScreenDesignerListItem>(
                                                                                dbContext,
                                                                                Command,
                                                                                userId,
                                                                                culture,
                                                                                CriteriaPurposeCodes.WindowControl, //  @psPurposeCode
                                                                                null, //  @pnCaseOfficeID
                                                                                null, //@psProgramID
                                                                                null, //  @psCaseType
                                                                                null, //  @psCountryCode
                                                                                null, //  @psPropertyType
                                                                                null, //  @psCaseCategory
                                                                                null, //  @psSubType
                                                                                null, //  @psBasis
                                                                                null, // @pnProfileKey
                                                                                null, //  @pnRuleInUse
                                                                                null, // @pbExactMatch
                                                                                null, //  @pbUserDefinedRule
                                                                                string.Join(",", ids)// @psCriteriaNumbers
                                                                               );
        }
    }
}