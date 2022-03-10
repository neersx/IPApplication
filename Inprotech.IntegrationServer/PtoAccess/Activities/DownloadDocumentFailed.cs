using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Activities
{
    public class DownloadDocumentFailed
    {
        readonly IRepository _repository;
        readonly IGlobErrors _globErrors;
        readonly Func<DateTime> _now;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IArtifactsService _artefactsService;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;

        public DownloadDocumentFailed(IRepository repository, IGlobErrors globErrors, Func<DateTime> now, 
            IDataDownloadLocationResolver dataDownloadLocationResolver,
            IArtifactsService artefactsService,
            IScheduleRuntimeEvents scheduleRuntimeEvents)
        {
            _repository = repository;
            _globErrors = globErrors;
            _now = now;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _artefactsService = artefactsService;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
        }

        public async Task NotifyFailure(DataDownload dataDownload, Document document)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));
            if (document == null) throw new ArgumentNullException(nameof(document));

            var toSave =
                _repository.Set<Document>()
                    .SingleOrDefault(_ => _.DocumentObjectId == document.DocumentObjectId && _.Source == document.Source) ??
                _repository.Set<Document>().Add(
                        new Document
                        {
                            Source = dataDownload.DataSourceType,
                            DocumentObjectId = document.DocumentObjectId,
                            ApplicationNumber = document.ApplicationNumber,
                            RegistrationNumber = document.RegistrationNumber,
                            MailRoomDate = document.MailRoomDate,
                            PageCount = document.PageCount,
                            DocumentCategory = document.DocumentCategory,
                            DocumentDescription = document.DocumentDescription,
                            CreatedOn = _now(),
                            Reference = Guid.NewGuid()
                        });

            toSave.Errors = JsonConvert.SerializeObject(await _globErrors.For(dataDownload, document.DocumentObjectId));
            toSave.Status = DocumentDownloadStatus.Failed;
            toSave.UpdatedOn = _now();

            _repository.SaveChanges();

            var location = _dataDownloadLocationResolver.Resolve(dataDownload);
            var artifacts = _artefactsService.CreateCompressedArchive(location);

            _scheduleRuntimeEvents.DocumentFailed(dataDownload.Id, toSave, artifacts);
        }
    }
}
