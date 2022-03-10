using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Extensibility;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IApplicationDocuments
    {
        Task<Activity> Download(Session session, ApplicationDownload download);
    }

    public class ApplicationDocuments : IApplicationDocuments
    {
        readonly IArtifactsLocationResolver _artifactsLocation;
        readonly IBufferedStringReader _bufferedStringReader;
        readonly IBiblioStorage _biblioStorage;
        readonly IFileSystem _fileSystem;
        readonly IPrivatePairRuntimeEvents _pairRuntimeEvents;

        public ApplicationDocuments(IArtifactsLocationResolver artifactsLocation, IFileSystem fileSystem, IPrivatePairRuntimeEvents pairRuntimeEvents, IBufferedStringReader bufferedStringReader, IBiblioStorage biblioStorage)
        {
            _artifactsLocation = artifactsLocation;
            _fileSystem = fileSystem;
            _pairRuntimeEvents = pairRuntimeEvents;
            _bufferedStringReader = bufferedStringReader;
            _biblioStorage = biblioStorage;
        }

        public async Task<Activity> Download(Session session, ApplicationDownload applicationDownload)
        {
            var applicationFolderLocation = _artifactsLocation.Resolve(applicationDownload);
            var biblioInfo = await _biblioStorage.GetFileStoreBiblioInfo(applicationDownload.ApplicationId);
            Activity downloadBiblio = DefaultActivity.NoOperation();
            var latestDate = biblioInfo.date;
            var documentActivities = new List<Activity>();

            foreach (var messageFile in _fileSystem.Files(applicationFolderLocation, "*.json"))
            {
                var message = JsonConvert.DeserializeObject<Message>(await _bufferedStringReader.Read(messageFile));
                if (message.Meta.EventDateParsed > latestDate)
                {
                    var biblioLink = message.Links.For(LinkTypes.Biblio);
                    if (biblioLink != null)
                    {
                        downloadBiblio = Activity.Run<IDocumentDownload>(_ => _.DownloadIfRequired(applicationDownload, biblioLink, message.Meta.ServiceId))
                                                 .Then(Activity.Run<IBiblioStorage>(_ => _.StoreBiblio(applicationDownload, message.Meta.EventDateParsed)));
                        latestDate = message.Meta.EventDateParsed;
                    }
                }

                var pdfLink = message.Links.For(LinkTypes.Pdf);
                if (pdfLink != null)
                {
                    documentActivities.Add(Activity.Run<IDocumentDownload>(_ => _.DownloadIfRequired(applicationDownload, pdfLink, message.Meta.ServiceId))
                                                   .ExceptionFilter<IPtoFailureLogger>((c, e) => e.LogDocumentDownloadError(c, applicationDownload, pdfLink))
                                                   .Failed(Activity.Run<IDocumentDownloadFailure>(d => d.NotifyFailure(applicationDownload, pdfLink, messageFile)))
                                                   .ThenContinue());
                }
            }

            await _pairRuntimeEvents.TrackDocumentProgress(applicationDownload, documentActivities.Count, new AvailableDocument[0]);

            if (!documentActivities.Any())
            {
                return Activity.Run<IPrivatePairRuntimeEvents>(r => r.CaseProcessed(session, applicationDownload));
            }

            var validateBiblio = Activity.Run<IBiblioStorage>(_ => _.ValidateBiblio(session, applicationDownload));
            var downloadAndValidateBiblio = Activity.Sequence(downloadBiblio, validateBiblio)
                                                    .AnyFailed(Activity.Run<IDocumentDownloadFailure>(d => d.NotifyBiblioFailure(applicationDownload)));

            var downloadDocuments = Activity.Sequence(documentActivities);
            var processDownloadedDocuments = Activity.Run<IProcessApplicationDocuments>(_ => _.ProcessDownloadedDocuments(session, applicationDownload));

            return Activity.Sequence(downloadAndValidateBiblio, downloadDocuments, processDownloadedDocuments)
                           .AnyFailed(Activity.Run<IApplicationDownloadFailed>(_ => _.SaveArtifactAndNotify(applicationDownload)));
        }
    }
}