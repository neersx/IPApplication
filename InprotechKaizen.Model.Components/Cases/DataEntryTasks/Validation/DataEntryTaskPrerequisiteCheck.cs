using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation
{
    public interface IDataEntryTaskPrerequisiteCheck
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        Task<DataEntryTaskPrerequisiteCheckResult> Run(Case @case, DataEntryTask dataEntryTask);
    }

    /// <summary>
    ///     Performs the prerequisite checks prior to performing a data entry.
    /// </summary>
    public class DataEntryTaskPrerequisiteCheck : IDataEntryTaskPrerequisiteCheck
    {
        readonly ICaseCreditLimitChecker _caseCreditLimitChecker;
        readonly ICaseAuthorization _caseAuthorization;
        readonly ICaseNamesWithDebtorStatus _caseNamesWithDebtorStatus;

        public DataEntryTaskPrerequisiteCheck(
            ICaseAuthorization caseAuthorization,
            ICaseNamesWithDebtorStatus caseNamesWithDebtorStatus,
            ICaseCreditLimitChecker caseCreditLimitChecker)
        {
            _caseAuthorization = caseAuthorization;
            _caseNamesWithDebtorStatus = caseNamesWithDebtorStatus;
            _caseCreditLimitChecker = caseCreditLimitChecker;
        }

        public async Task<DataEntryTaskPrerequisiteCheckResult> Run(Case @case, DataEntryTask dataEntryTask)
        {
            if(@case == null) throw new ArgumentNullException(nameof(@case));
            if(dataEntryTask == null) throw new ArgumentNullException(nameof(dataEntryTask));

            var canView = await _caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Select);

            var canUpdate = await _caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update);

            return new DataEntryTaskPrerequisiteCheckResult(
                canView.IsUnauthorized,
                !@case.CurrentOpenActions()
                      .ByCriteria(dataEntryTask.Criteria.Id)
                      .Any(),
                _caseNamesWithDebtorStatus.For(@case).ToArray(),
                _caseCreditLimitChecker.NamesExceededCreditLimit(@case).ToArray(),
                canUpdate.IsUnauthorized);
        }
    }
}