using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Extensibility;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IProcessApplicationDocuments
    {
        Task<Activity> ProcessDownloadedDocuments(Session session, ApplicationDownload application);
    }

    public class ProcessApplicationDocuments : IProcessApplicationDocuments
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IFileSystem _fileSystem;
        readonly IDocumentUpdate _documentUpdate;
        readonly IFileNameExtractor _fileNameExtractor;
        readonly IBiblioStorage _biblioStorage;

        public ProcessApplicationDocuments(IArtifactsLocationResolver artifactsLocationResolver, IFileSystem fileSystem, IDocumentUpdate documentUpdate,
                                           IFileNameExtractor fileNameExtractor, IBiblioStorage biblioStorage)
        {
            _artifactsLocationResolver = artifactsLocationResolver;
            _fileSystem = fileSystem;
            _documentUpdate = documentUpdate;
            _fileNameExtractor = fileNameExtractor;
            _biblioStorage = biblioStorage;
        }

        public async Task<Activity> ProcessDownloadedDocuments(Session session, ApplicationDownload application)
        {
            var filesLocation = _artifactsLocationResolver.ResolveFiles(application);
            var biblioData = await _biblioStorage.Read(application);
            _fileSystem.EnsureFolderExists(filesLocation);

            foreach (var file in _fileSystem.Files(filesLocation, "*.pdf"))
            {
                var documentName = _fileNameExtractor.AbsoluteUriName(file);

                var fileWrapper = biblioData.ImageFileWrappers.First(_ => _.FileName == documentName);
                await _documentUpdate.Apply(session, application, fileWrapper.ToAvailableDocument());
            }

            var convertAndNotify = Activity.Run<IDetailsWorkflow>(e => e.ConvertNotifyAndSendDocsToDms(session, application));
            var indicateCaseProcessed = Activity.Run<IPrivatePairRuntimeEvents>(r => r.CaseProcessed(session, application));

            var handleError = Activity.Run<IApplicationDownloadFailed>(_ => _.SaveArtifactAndNotify(application));

            return Activity.Sequence(convertAndNotify, indicateCaseProcessed)
                           .AnyFailed(handleError);
        }
    }
}