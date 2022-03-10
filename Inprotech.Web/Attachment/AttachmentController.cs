using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Attachments;

namespace Inprotech.Web.Attachment
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/attachment")]
    public class AttachmentController : ApiController
    {
        readonly IActivityAttachmentAccessResolver _activityAttachmentAccessResolver;
        readonly IActivityAttachmentFileNameResolver _activityAttachmentFileNameResolver;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ISubjectSecurityProvider _subjectSecurityProvider;
        readonly IAttachmentContentLoader _attachmentContentLoader;
        readonly IAttachmentSettings _attachmentSettings;
        readonly IStorageServiceClient _storageServiceClient;

        public AttachmentController(IStorageServiceClient storageServiceClient,
                                    IActivityAttachmentAccessResolver activityAttachmentAccessResolver,
                                    IAttachmentContentLoader attachmentContentLoader,
                                    IAttachmentSettings attachmentSettings,
                                    IActivityAttachmentFileNameResolver activityAttachmentFileNameResolver,
                                    ITaskSecurityProvider taskSecurityProvider,
                                    ISubjectSecurityProvider subjectSecurityProvider)
        {
            _storageServiceClient = storageServiceClient;
            _activityAttachmentAccessResolver = activityAttachmentAccessResolver;
            _attachmentContentLoader = attachmentContentLoader;
            _attachmentSettings = attachmentSettings;
            _activityAttachmentFileNameResolver = activityAttachmentFileNameResolver;
            _taskSecurityProvider = taskSecurityProvider;
            _subjectSecurityProvider = subjectSecurityProvider;
        }

        [HttpGet]
        [Route("view")]
        public async Task<dynamic> View()
        {
            return new
            {
                CanMaintainCaseAttachments = new
                {
                    CanAdd = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Create),
                    CanEdit = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Modify),
                    CanDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Delete)
                },
                CanViewCaseAttachments = _subjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments),
                CanAccessDocumentsFromDms = _taskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms),
                CanMaintainPriorArtAttachments = new
                {
                    CanAdd = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArtAttachment, ApplicationTaskAccessLevel.Create),
                    CanEdit = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArtAttachment, ApplicationTaskAccessLevel.Modify),
                    CanDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArtAttachment, ApplicationTaskAccessLevel.Delete)
                }
            };
        }

        [HttpGet]
        [Route("validatePath")]
        public async Task<bool> ValidatePath(string path)
        {
            if (path == null) throw new ArgumentNullException(nameof(path));

            if (string.IsNullOrWhiteSpace(path)) return false;

            return await _storageServiceClient.ValidatePath(path, Request);
        }

        [HttpGet]
        [Route("validateDirectory")]
        public async Task<DirectoryValidationResult> ValidateDirectory(string path)
        {
            if (path == null) throw new ArgumentNullException(nameof(path));

            if (string.IsNullOrWhiteSpace(path))
                return new DirectoryValidationResult();

            return await _storageServiceClient.ValidateDirectory(path, Request);
        }

        [HttpGet]
        [Route("directory")]
        public async Task<HttpResponseMessage> GetDirectoryFolders()
        {
            return await _storageServiceClient.GetDirectoryFolders(Request);
        }

        [HttpGet]
        [Route("files")]
        public async Task<HttpResponseMessage> GetDirectoryFiles(string path)
        {
            return await _storageServiceClient.GetDirectoryFiles(path, Request);
        }

        [HttpPost]
        [Route("uploadFiles")]
        public async Task<HttpResponseMessage> UploadFiles()
        {
            if (!Request.Content.IsMimeMultipartContent())
            {
                return new HttpResponseMessage(HttpStatusCode.UnsupportedMediaType);
            }

            var response = await _storageServiceClient.UploadFile(Request);

            return response;
        }

        [HttpGet]
        [Route("storageLocation")]
        public async Task<AttachmentSetting.StorageLocation> GetStorageLocation(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException(nameof(path));

            var settings = await _attachmentSettings.Resolve();

            return settings?.GetStorageLocation(path);
        }

        [HttpGet]
        [Route("file")]
        public async Task<HttpResponseMessage> GetFile(int activityKey, int? sequenceKey, string path)
        {
            if (await _activityAttachmentAccessResolver.CheckAccessForExternalUser(activityKey, sequenceKey ?? 0))
            {
                if (_attachmentContentLoader.TryLoadAttachmentContent(activityKey, sequenceKey ?? 0, out var content))
                {
                    var response = Request.CreateResponse(HttpStatusCode.OK);
                    response.Content = new ByteArrayContent(content.Content);
                    response.Content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
                    response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment") {FileName = content.FileName};
                    response.Headers.CacheControl = new CacheControlHeaderValue
                    {
                        NoCache = true,
                        NoStore = true,
                        MaxAge = TimeSpan.Zero
                    };
                    return response;
                }

                if (string.IsNullOrWhiteSpace(path))
                {
                    path = _activityAttachmentFileNameResolver.Resolve(activityKey, sequenceKey);
                }

                return await _storageServiceClient.GetFile(activityKey, sequenceKey, path, Request);
            }

            return Request.CreateResponse(HttpStatusCode.Forbidden);
        }
    }
}