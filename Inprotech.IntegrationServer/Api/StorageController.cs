using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Storage;

namespace Inprotech.IntegrationServer.Api
{
    [RequiresApiKey(ExternalApplicationName.InprotechServer, IsOneTimeUse = true)]
    public class StorageController : ApiController
    {
        readonly IFileSystem _fileSystem;
        readonly IRepository _repository;
        readonly IIndex<DataSourceType, ISourceImageDownloadHandler> _sourceImageDownloadHandler;

        public StorageController(IRepository repository,
                                    IFileSystem fileSystem,
                                    IIndex<DataSourceType, ISourceImageDownloadHandler> sourceImageDownloadHandler)
        {
            _repository = repository;
            _fileSystem = fileSystem;
            _sourceImageDownloadHandler = sourceImageDownloadHandler;
        }

        [HttpGet]
        [Route("api/uspto/storage/cpaxml")] // Legacy Inprotech Route
        [Route("api/dataextract/storage/cpaxml")]
        public HttpResponseMessage CpaXml(int notificationId)
        {
            var notification = _repository.Set<CaseNotification>()
                                          .Single(cn => cn.Id == notificationId);

            var path = notification.Case.FileStore.Path;

            if (!_fileSystem.Exists(path)) return new HttpResponseMessage(HttpStatusCode.NotFound);

            var result = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StreamContent(_fileSystem.OpenRead(path))
            };
            result.Content.Headers.ContentType = new MediaTypeHeaderValue("text/xml");

            return result;
        }

        [HttpGet]
        [Route("api/filestore/{id:int}")]
        public HttpResponseMessage Get(int id)
        {
            var fs = _repository.Set<FileStore>().SingleOrDefault(_ => _.Id == id);
            if (fs == null)
            {
                return new HttpResponseMessage(HttpStatusCode.NotFound);
            }

            var response = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StreamContent(_fileSystem.OpenRead(fs.Path))
            };
            response.Content.Headers.ContentType = new MediaTypeHeaderValue(MimeMapping.GetMimeMapping(fs.OriginalFileName));
            return response;
        }

        [HttpGet]
        [Route("api/dataextract/storage/image")]
        public async Task<HttpResponseMessage> Image(int notificationId, bool refresh = false)
        {
            var notification = _repository.Set<CaseNotification>()
                                          .Single(cn => cn.Id == notificationId);

            var caseFile = _repository.Set<CaseFiles>()
                                      .OrderByDescending(_ => _.Id)
                                      .FirstOrDefault(cf => cf.CaseId == notification.CaseId && cf.Type == (int) CaseFileType.MarkImage);
            var fileStore = _repository.Set<FileStore>().Single(fs => fs.Id == caseFile.FileStoreId);
            var path = fileStore.Path;

            if (refresh)
            {
                var imagePath = path.Replace(fileStore.OriginalFileName, String.Empty);
                await Refresh(notification, imagePath);
            }

            var result = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StreamContent(_fileSystem.OpenRead(path))
            };
            result.Content.Headers.ContentType = new MediaTypeHeaderValue(string.IsNullOrEmpty(fileStore.MediaType) ? "image/png" : fileStore.MediaType);
            return result;
        }

        async Task Refresh(CaseNotification notification, string imagePath)
        {
            var source = notification.Case.Source;
            if (!_sourceImageDownloadHandler.TryGetValue(notification.Case.Source, out var imageDownloadHandler))
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            var eligibleCase = new EligibleCase(notification.Case.CorrelationId.GetValueOrDefault(),
                                                notification.Case.Jurisdiction,
                                                ExternalSystems.SystemCode(source));
            
            await imageDownloadHandler.Download(eligibleCase, notification.Case.FileStore.Path, imagePath);
        }
    }
}