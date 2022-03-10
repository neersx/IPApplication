using System;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    /// <summary>
    /// Generates a notification if newly available case details 
    /// is different to last seen version.
    /// </summary>
    public class NewCaseDetailsAvailableNotification
    {
        readonly IRepository _repository;
        readonly IPtoAccessCase _ptoAccessCase;
        readonly IContentHasher _contentHasher;
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IBufferedStringReader _bufferedStringReader;

        public NewCaseDetailsAvailableNotification(
            IRepository repository, IPtoAccessCase ptoAccessCase,
            IContentHasher contentHasher, IArtifactsLocationResolver artifactsLocationResolver, IBufferedStringReader bufferedStringReader)
        {
            _repository = repository;
            _ptoAccessCase = ptoAccessCase;
            _contentHasher = contentHasher;
            _artifactsLocationResolver = artifactsLocationResolver;
            _bufferedStringReader = bufferedStringReader;
        }

        public async Task SendAlways(ApplicationDownload application)
        {
            if (application == null) throw new ArgumentNullException(nameof(application));

            await SendNotification(application, true);
        }

        public async Task Send(ApplicationDownload application)
        {
            if (application == null) throw new ArgumentNullException(nameof(application));

            await SendNotification(application, false);
        }

        async Task SendNotification(ApplicationDownload application, bool forceNotification)
        {
            var cpaXmlPath = _artifactsLocationResolver.Resolve(application, PtoAccessFileNames.CpaXml);

            var cpaXmlContent = await _bufferedStringReader.Read(cpaXmlPath);

            var hash = _contentHasher.ComputeHash(cpaXmlContent);

            var @case =
                _repository.Set<Case>()
                           .Single(
                                   c =>
                                       c.Source == DataSourceType.UsptoPrivatePair &&
                                       c.ApplicationNumber == application.Number);

            var errorNotification =
                _repository.Set<CaseNotification>()
                           .SingleOrDefault(_ => _.CaseId == @case.Id && _.Type == CaseNotificateType.Error);

            if (hash != @case.Version || forceNotification || errorNotification != null)
            {
                var title = ExtractTitle(cpaXmlContent);

                /* IntegrationCase.ApplicationNumber should not be overridden by the Application Number held from Inprotech side */
                /* this is to maintain a link from the xml source from Private PAIR */

                _ptoAccessCase.Update(cpaXmlPath, @case, hash);
                _ptoAccessCase.CreateOrUpdateNotification(@case, title);

                _repository.SaveChanges();
            }
        }

        string ExtractTitle(string applicationDetails)
        {
            var doc = XElement.Parse(applicationDetails);
            var ns = doc.Name.Namespace;
            return doc.Descendants(ns + "SenderDetails")
                      .Select(_ => (string)_.Element(ns + "SenderRequestIdentifier"))
                      .SingleOrDefault();
        }
    }
}