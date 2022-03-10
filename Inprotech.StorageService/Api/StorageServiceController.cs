using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.StorageService.Storage;
using Inprotech.Web.Configuration.Attachments;

namespace Inprotech.StorageService.Api
{
    [RequiresApiKey(ExternalApplicationName.InprotechServer, IsOneTimeUse = true)]
    [RoutePrefix("api")]
    public class StorageServiceController : ApiController
    {
        readonly IFileHelpers _fileHelpers;
        readonly IStorageService _storageService;

        public StorageServiceController(IStorageService storageService, IFileHelpers fileHelpers)
        {
            _storageService = storageService;
            _fileHelpers = fileHelpers;
        }

        [HttpPost]
        [Route("refresh")]
        public async Task Refresh(AttachmentSetting settings)
        {
            await _storageService.RebuildDirectoryCaching(settings);
        }

        [HttpGet]
        [Route("validatePath")]
        public async Task<bool> ValidatePath(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) return false;

            return await _storageService.ValidatePath(path);
        }

        [HttpGet]
        [Route("validateDirectory")]
        public async Task<DirectoryValidationResult> ValidateDirectory(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                return new DirectoryValidationResult {DirectoryExists = false, IsLinkedToStorageLocation = false};
            }

            return await _storageService.ValidateDirectory(path);
        }

        [HttpGet]
        [Route("directory")]
        public async Task<StorageDirectoryResponse> GetDirectoryFolders()
        {
            return await _storageService.GetDirectoryFolders();
        }

        [HttpGet]
        [Route("files")]
        public async Task<IEnumerable<StorageFile>> GetDirectoryFiles(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) return new List<StorageFile>();

            return await _storageService.GetDirectoryFiles(path);
        }

        [HttpPost]
        [Route("uploadFile")]
        public async Task<HttpResponseMessage> UploadFiles()
        {
            if (!Request.Content.IsMimeMultipartContent())
            {
                return new HttpResponseMessage(HttpStatusCode.UnsupportedMediaType);
            }

            var data = await Request.Content.ReadAsMultipartAsync();

            if (data.Contents.Count != 2)
            {
                throw new ArgumentException("Content Format");
            }

            var file = new FileToUpload
            {
                FileName = data.Contents[1].Headers.ContentDisposition.FileName,
                FolderPath = await data.Contents[0].ReadAsStringAsync(),
                FileBytes = await data.Contents[1].ReadAsByteArrayAsync()
            };

            return await _storageService.SaveFile(file);
        }

        [HttpGet]
        [Route("file")]
        public async Task<HttpResponseMessage> GetFile(string path)
        {
            var response = Request.CreateResponse(HttpStatusCode.OK);
            var filePath = await _storageService.GetTranslatedFilePath(path);
            if (string.IsNullOrWhiteSpace(filePath) || !_fileHelpers.Exists(filePath))
            {
                return Request.CreateResponse(HttpStatusCode.NotFound);
            }

            response.Content = new StreamContent(new FileStream(filePath, FileMode.Open));
            response.Content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
            var fileName = Path.GetFileName(filePath);
            response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
            {
                FileName = fileName
            };
            response.Headers.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true,
                NoStore = true,
                MaxAge = TimeSpan.Zero
            };
            return response;
        }
    }
}