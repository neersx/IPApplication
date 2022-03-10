using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Cases.Restrictions;

namespace Inprotech.Tests.Web.Builders.Model.DataEntryTasks.Validation
{
    public class BatchDataEntryTaskPrerequisiteCheckResultBuilder : IBuilder<BatchDataEntryTaskPrerequisiteCheckResult>
    {
        public bool? HasMultipleOpenActionCycles { get; set; }
        public CaseNameRestriction[] CaseNameRestrictions { get; set; }
        public CaseName[] CaseNamesWithCreditLimitExceeded { get; set; }

        public BatchDataEntryTaskPrerequisiteCheckResult Build()
        {
            return new BatchDataEntryTaskPrerequisiteCheckResult(
                                                                 new DataEntryTaskPrerequisiteCheckResultBuilder
                                                                 {
                                                                     CaseNamesWithCreditLimitExceeded = CaseNamesWithCreditLimitExceeded,
                                                                     CaseNameRestrictions = CaseNameRestrictions
                                                                 }.Build(),
                                                                 HasMultipleOpenActionCycles ?? false
                                                                );
        }
    }
}