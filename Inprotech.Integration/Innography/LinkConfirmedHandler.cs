using System;
using System.Threading.Tasks;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.PostSourceUpdate;

namespace Inprotech.Integration.Innography
{
    public class LinkConfirmedHandler : ISourceNotificationReviewedHandler, ISourceUpdatedHandler
    {
        readonly ICpaXmlProvider _cpaXmlProvider;
        readonly IInnographyIdFromCpaXml _innographyIdFromCpaXml;
        readonly IInnographyIdUpdater _innographyIdUpdater;

        public LinkConfirmedHandler(IInnographyIdUpdater innographyIdUpdater, ICpaXmlProvider cpaXmlProvider, IInnographyIdFromCpaXml innographyIdFromCpaXml)
        {
            _innographyIdUpdater = innographyIdUpdater;
            _cpaXmlProvider = cpaXmlProvider;
            _innographyIdFromCpaXml = innographyIdFromCpaXml;
        }

        public async Task Handle(CaseNotification notification)
        {
            if (notification == null) throw new ArgumentNullException(nameof(notification));

            if (notification.Case == null) throw new ArgumentNullException(nameof(notification));

            if (notification.Case.Source != DataSourceType.IpOneData) InvalidOperation("Source not supported");

            if (notification.Case.CorrelationId == null) InvalidOperation("Inprotech case is unknown");

            var innographyId = _innographyIdFromCpaXml.Resolve(await _cpaXmlProvider.For(notification.Id));

            await _innographyIdUpdater.Update(notification.Case.CorrelationId.GetValueOrDefault(), innographyId);
        }

        public async Task Handle(int caseId, string rawCpaXml)
        {
            var innographyId = _innographyIdFromCpaXml.Resolve(rawCpaXml);

            await _innographyIdUpdater.Update(caseId, innographyId);
        }

        static void InvalidOperation(string message)
        {
            throw new InvalidOperationException(message);
        }
    }
}