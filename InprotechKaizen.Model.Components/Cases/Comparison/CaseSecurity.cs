using System;
using System.Diagnostics.CodeAnalysis;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Components.Cases.Comparison
{
    public interface ICaseSecurity
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        Task<bool> CanAcceptChanges(Case @case);
    }

    public class CaseSecurity : ICaseSecurity
    {
        readonly ICaseAuthorization _caseAuthorization;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public CaseSecurity(ICaseAuthorization caseAuthorization, ITaskSecurityProvider taskSecurityProvider)
        {
            _caseAuthorization = caseAuthorization;
            _taskSecurityProvider = taskSecurityProvider;
        }

        public async Task<bool> CanAcceptChanges(Case @case)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var r = await _caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update);
            if (!r.Exists) throw new InvalidOperationException("Case must exist");

            return !r.IsUnauthorized && _taskSecurityProvider.HasAccessTo(ApplicationTask.SaveImportedCaseData);
        }
    }
}