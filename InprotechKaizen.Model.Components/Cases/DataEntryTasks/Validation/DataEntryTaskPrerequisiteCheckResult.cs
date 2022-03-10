using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Restrictions;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation
{
    public class DataEntryTaskPrerequisiteCheckResult
    {
        protected DataEntryTaskPrerequisiteCheckResult(DataEntryTaskPrerequisiteCheckResult from)
        {
            if (from == null)
            {
                CaseNameRestrictions = new CaseNameRestriction[0];
                return;
            }

            CaseAccessSecurityFailed = from.CaseAccessSecurityFailed;
            DataEntryTaskIsUnavailable = from.DataEntryTaskIsUnavailable;
            CaseNameRestrictions = from.CaseNameRestrictions;
            CaseNamesWithCreditLimitExceeded = from.CaseNamesWithCreditLimitExceeded;
            CaseAccessSelectSecurityFailed = from.CaseAccessSelectSecurityFailed;
        }

        public DataEntryTaskPrerequisiteCheckResult(
            bool caseAccessSecurityFailed = false,
            bool dataEntryTaskIsUnavailable = false,
            CaseNameRestriction[] caseNameRestrictions = null,
            CaseName[] creditLimitExceeded = null,
            bool caseAccessSelectSecurityFailed = false)
        {
            CaseAccessSecurityFailed = caseAccessSecurityFailed;
            DataEntryTaskIsUnavailable = dataEntryTaskIsUnavailable;
            CaseNameRestrictions = caseNameRestrictions ?? new CaseNameRestriction[0];
            CaseNamesWithCreditLimitExceeded = creditLimitExceeded ?? new CaseName[0];
            CaseAccessSelectSecurityFailed = caseAccessSelectSecurityFailed;
        }

        public bool CaseAccessSecurityFailed { get; }
        public bool DataEntryTaskIsUnavailable { get; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public CaseNameRestriction[] CaseNameRestrictions { get; set; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public CaseName[] CaseNamesWithCreditLimitExceeded { get; set; }

        public bool CaseAccessSelectSecurityFailed { get; }

        public virtual bool HasErrors
        {
            get
            {
                return CaseAccessSecurityFailed ||
                       DataEntryTaskIsUnavailable ||
                       CaseNameRestrictions.Any(
                                                cnr =>
                                                    cnr.Status.RestrictionAction == KnownDebtorRestrictions.DisplayError ||
                                                    cnr.Status.RestrictionAction ==
                                                    KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation);
            }
        }
    }
}