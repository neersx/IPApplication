using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Configuration.Rules.Workflow
{
    public static class WorkflowSearchCommand
    {
        public const string Command = "ipw_WorkflowSearch";

        public static IEnumerable<WorkflowSearchListItem> WorkflowSearch(
            this IDbContext dbContext,
            int userId,
            string culture,
            SearchCriteria c
            )
        {
            return DbContextHelpers.ExecuteSqlQuery<WorkflowSearchListItem>(
                                                                            dbContext,
                                                                            Command,
                                                                            userId,
                                                                            culture,
                                                                            CriteriaPurposeCodes.EventsAndEntries, //  @psPurposeCode
                                                                            c.Office, //  @pnCaseOfficeID
                                                                            c.CaseType, //  @psCaseType
                                                                            c.Action, //  @psAction
                                                                            c.PropertyType, //  @psPropertyType
                                                                            c.Jurisdiction, //  @psCountryCode
                                                                            c.CaseCategory, //  @psCaseCategory
                                                                            c.SubType, //  @psSubType
                                                                            c.Basis, //  @psBasis
                                                                            c.ApplyTo == ClientFilterOptions.Na ? (bool?) null : c.ApplyTo == ClientFilterOptions.LocalClients, //  @pnLocalClientFlag
                                                                            c.DateOfLaw == null ? (DateTime?) null : DateTime.Parse(c.DateOfLaw), //  @pdtDateOfAct
                                                                            c.IncludeCriteriaNotInUse.GetValueOrDefault() ? (bool?) null : true, //  @pnRuleInUse
                                                                            c.MatchType == CriteriaMatchOptions.ExactMatch, //  @pbExactMatch       
                                                                            c.IncludeProtectedCriteria.GetValueOrDefault() ? (bool?) null : true, //  @pbUserDefinedRule
                                                                            null,
                                                                            c.Event,
                                                                            c.ExaminationType ?? c.RenewalType
                );
        }

        public static IEnumerable<WorkflowSearchListItem> WorkflowSearchById(
            this IDbContext dbContext,
            int userId,
            string culture,
            IEnumerable<int> criteriaNumbers)
        {
            return DbContextHelpers.ExecuteSqlQuery<WorkflowSearchListItem>(
                                                                            dbContext,
                                                                            Command,
                                                                            userId,
                                                                            culture,
                                                                            CriteriaPurposeCodes.EventsAndEntries, //  @psPurposeCode
                                                                            null, //  @pnCaseOfficeID
                                                                            null, //  @psCaseType
                                                                            null, //  @psAction
                                                                            null, //  @psPropertyType
                                                                            null, //  @psCountryCode
                                                                            null, //  @psCaseCategory
                                                                            null, //  @psSubType
                                                                            null, //  @psBasis
                                                                            null, //  @pnLocalClientFlag
                                                                            null, //  @pdtDateOfAct
                                                                            null, //  @pnRuleInUse
                                                                            null, //  @pbExactMatch     
                                                                            null, //  @pbUserDefinedRule
                                                                            string.Join(",", criteriaNumbers),
                                                                            null, // @pnEventNo
                                                                            null // @pnTableCode
                );
        }
    }

    public class WorkflowSearchListItem
    {
        public int Id { get; set; }
        public string CriteriaName { get; set; }
        public int? OfficeCode { get; set; }
        public string OfficeDescription { get; set; }
        public string CaseTypeCode { get; set; }
        public string CaseTypeDescription { get; set; }
        public string JurisdictionCode { get; set; }
        public string JurisdictionDescription { get; set; }
        public string PropertyTypeCode { get; set; }
        public string PropertyTypeDescription { get; set; }
        public string CaseCategoryCode { get; set; }
        public string CaseCategoryDescription { get; set; }
        public string SubTypeCode { get; set; }
        public string SubTypeDescription { get; set; }
        public string BasisCode { get; set; }
        public string BasisDescription { get; set; }
        public string ActionCode { get; set; }
        public string ActionDescription { get; set; }
        public DateTime? DateOfLaw { get; set; }
        public bool IsLocalClient { get; set; }
        public bool InUse { get; set; }
        public bool IsProtected { get; set; }
        public bool IsInherited { get; set; }
        public bool IsParent { get; set; }
        public string ExaminationTypeDescription { get; set; }
        public string RenewalTypeDescription { get; set; }
        public string BestFit { get; set; }
    }
}