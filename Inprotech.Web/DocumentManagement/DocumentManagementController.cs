using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Exceptions;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;

namespace Inprotech.Web.DocumentManagement
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/document-management")]
    [RequiresAccessTo(ApplicationTask.AccessDocumentsfromDms)]
    public class DocumentManagementController : ApiController
    {
        readonly IDmsDocuments _dmsDocuments;
        readonly ICaseDmsFolders _dmsFolders;

        public DocumentManagementController(ICaseDmsFolders dmsFolders, IDmsDocuments dmsDocuments)
        {
            _dmsFolders = dmsFolders;
            _dmsDocuments = dmsDocuments;
        }

        [HttpGet]
        [Route("folder/{searchStringOrPath}/{fetchChild}")]
        [HandleException(typeof(OAuth2TokenException), typeof(HandleOAuthExceptions))]
        public async Task<IEnumerable<DmsFolder>> GetSubFolders(string searchStringOrPath,
                                                                [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "options")] FolderDocumentCriteria options = null,
                                                                bool fetchChild = false)
        {
            if (string.IsNullOrWhiteSpace(searchStringOrPath)) throw new ArgumentNullException(nameof(searchStringOrPath));

            return await _dmsFolders.FetchSubFolders(searchStringOrPath, GetFolderType(options), fetchChild);
        }

        [HttpGet]
        [Route("documents/{searchStringOrPath}")]
        [HandleException(typeof(OAuth2TokenException), typeof(HandleOAuthExceptions))]
        public async Task<PagedResults> GetDocuments(string searchStringOrPath, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp = null,
                                                     [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "options")] FolderDocumentCriteria options = null)
        {
            if (string.IsNullOrWhiteSpace(searchStringOrPath)) throw new ArgumentNullException(nameof(searchStringOrPath));

            var queryParameters = qp ?? new CommonQueryParameters();

            var documentsCollection = await _dmsDocuments.Fetch(searchStringOrPath, GetFolderType(options), queryParameters);

            var docs = documentsCollection.DmsDocuments.OrderByDescending(_ => _.DateCreated);
            var documentsData = docs.AsQueryable().OrderByProperty(queryParameters);

            return new PagedResults(documentsData, documentsCollection.TotalCount);
        }

        [HttpGet]
        [Route("document/{searchStringOrPath}")]
        [HandleException(typeof(OAuth2TokenException), typeof(HandleOAuthExceptions))]
        public async Task<DmsDocument> GetDocumentDetails(string searchStringOrPath)
        {
            if (string.IsNullOrWhiteSpace(searchStringOrPath)) throw new ArgumentNullException(nameof(searchStringOrPath));

            return await _dmsDocuments.FetchDocumentDetails(searchStringOrPath);
        }

        [HttpGet]
        [Route("download/{searchStringOrPath}")]
        [HandleException(typeof(OAuth2TokenException), typeof(HandleOAuthExceptions), HandlerAction = "HandleDocumentDownload")]
        public async Task<HttpResponseMessage> DownloadDocument(string searchStringOrPath)
        {
            if (string.IsNullOrWhiteSpace(searchStringOrPath)) throw new ArgumentNullException(nameof(searchStringOrPath));

            var response = await _dmsDocuments.Download(searchStringOrPath);

            if (response == null) return Request.CreateResponse(HttpStatusCode.NotFound);

            var result = Request.CreateResponse(HttpStatusCode.OK);
            result.Content = new StreamContent(new MemoryStream(response.DocumentData));
            result.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment") { FileName = response.FileName };
            result.Headers.Add("x-filename", response.FileName);
            result.Headers.Add("x-filetype", response.ContentType);
            result.Content.Headers.ContentType = new MediaTypeHeaderValue(response.ContentType);

            return result;
        }

        FolderType GetFolderType(FolderDocumentCriteria options) => FolderTypeMap.Map(options?.FolderType, null);

        public class FolderDocumentCriteria
        {
            public string FolderType { get; set; }
        }
    }
}