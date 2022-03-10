using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Cases.Extensions;

namespace Inprotech.Web.BatchEventUpdate
{
    public interface IWarnOnlyRestrictionsBuilder
    {
        IEnumerable<CaseNameRestrictionModel> Build(Case @case, DataEntryTaskPrerequisiteCheckResult checkResult);
    }

    public class WarnOnlyRestrictionsBuilder : IWarnOnlyRestrictionsBuilder
    {
        public IEnumerable<CaseNameRestrictionModel> Build(Case @case, DataEntryTaskPrerequisiteCheckResult checkResult)
        {
            var warnOnlyRestrictions = new[]
                                       {
                                            KnownDebtorRestrictions.DisplayWarning, KnownDebtorRestrictions.NoRestriction
                                       };

            return @case
                .CaseNames
                .Where(
                       cn =>
                       checkResult.CaseNamesWithCreditLimitExceeded.Contains(cn) ||
                       checkResult.CaseNameRestrictions.Any(
                                                             cnr =>
                                                             cn.Equals(cnr.CaseName) &&
                                                             cnr.CaseName.HasDebtorRestrictions(warnOnlyRestrictions)))
                .Select(
                        cn => new CaseNameRestrictionModel(
                                  cn,
                                  warnOnlyRestrictions,
                                  checkResult.CaseNamesWithCreditLimitExceeded.Any(cncle => cncle.Equals(cn)))
                ).ToArray();
        }
    }
}