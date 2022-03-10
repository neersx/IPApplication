using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Cases.Restrictions;

namespace Inprotech.Tests.Web.Builders.Model.DataEntryTasks.Validation
{
    public class DataEntryTaskPrerequisiteCheckResultBuilder : IBuilder<DataEntryTaskPrerequisiteCheckResult>
    {
        public bool? CaseAccessSecurityFailed { get; set; }
        public bool? DataEntryTaskIsUnavailable { get; set; }
        public CaseNameRestriction[] CaseNameRestrictions { get; set; }
        public CaseName[] CaseNamesWithCreditLimitExceeded { get; set; }
        public bool? CaseAccessSelectSecurityFailed { get; set; }

        public DataEntryTaskPrerequisiteCheckResult Build()
        {
            return new DataEntryTaskPrerequisiteCheckResult(
                                                            CaseAccessSecurityFailed ?? false,
                                                            DataEntryTaskIsUnavailable ?? false,
                                                            CaseNameRestrictions ?? new CaseNameRestriction[0],
                                                            CaseNamesWithCreditLimitExceeded ?? new CaseName[0],
                                                            CaseAccessSelectSecurityFailed ?? false
                                                           );
        }
    }
}