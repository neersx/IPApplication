using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Notifications;

namespace Inprotech.Integration.Innography
{
    public class SourceCaseMatchRejectable : ISourceCaseMatchRejectable
    {
        readonly ICaseAuthorization _caseAuthorization;
        readonly ICpaXmlProvider _cpaXmlProvider;
        readonly IInnographyIdFromCpaXml _innographyIdFromCpaXml;
        readonly IInnographyIdUpdater _innographyIdUpdater;

        public SourceCaseMatchRejectable(
            ICpaXmlProvider cpaXmlProvider,
            IInnographyIdFromCpaXml innographyIdFromCpaXml,
            IInnographyIdUpdater innographyIdUpdater,
            ICaseAuthorization caseAuthorization)
        {
            _cpaXmlProvider = cpaXmlProvider;
            _innographyIdFromCpaXml = innographyIdFromCpaXml;
            _innographyIdUpdater = innographyIdUpdater;
            _caseAuthorization = caseAuthorization;
        }

        public async Task Reject(CaseNotification caseNotification)
        {
            if (caseNotification == null) throw new ArgumentNullException(nameof(caseNotification));

            var inprotechCaseId = await ResolveCase(caseNotification);

            var cpaXml = await _cpaXmlProvider.For(caseNotification.Id);

            var innographyId = _innographyIdFromCpaXml.Resolve(cpaXml);

            await _innographyIdUpdater.Reject(inprotechCaseId, innographyId);
        }

        public async Task ReverseReject(CaseNotification caseNotification)
        {
            if (caseNotification == null) throw new ArgumentNullException(nameof(caseNotification));

            var inprotechCaseId = await ResolveCase(caseNotification);

            _innographyIdUpdater.Clear(inprotechCaseId);
        }

        async Task<int> ResolveCase(CaseNotification caseNotification)
        {
            var inprotechCaseId = caseNotification.Case.CorrelationId;
            if (inprotechCaseId == null) throw new ArgumentException("inprotech case id");
            
            var r = await _caseAuthorization.Authorize(inprotechCaseId.Value, AccessPermissionLevel.Update);

            if (!r.Exists)
            {
                throw new InvalidOperationException("Case not found or update case permission not available");
            }

            if (r.IsUnauthorized)
            {
                throw new DataSecurityException(r.ReasonCode.CamelCaseToUnderscore());
            }

            return inprotechCaseId.Value;
        }
    }
}