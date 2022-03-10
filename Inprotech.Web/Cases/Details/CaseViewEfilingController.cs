using System;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseViewEfilingController : ApiController
    {
        readonly ICaseViewEfiling _caseViewEfiling;
        readonly ISubjectSecurityProvider _securityProvider;
        readonly IEFilingCompatibility _eFilingCompatibility;
        readonly IEfilingFileViewer _efilingFileViewer;

        public CaseViewEfilingController(ICaseViewEfiling caseViewEfiling, ISubjectSecurityProvider securityProvider, IEFilingCompatibility eFilingCompatibility, IEfilingFileViewer efilingFileViewer)
        {
            _caseViewEfiling = caseViewEfiling;
            _securityProvider = securityProvider;
            _eFilingCompatibility = eFilingCompatibility;
            _efilingFileViewer = efilingFileViewer;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/efiling")]
        public PagedResults GetPackage(string caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            if (!_eFilingCompatibility.Status) return new PagedResults(null, 0);
            if (!_securityProvider.HasAccessToSubject(ApplicationSubject.EFiling)) return new PagedResults(null, 0);

            var result = _caseViewEfiling.GetPackages(caseKey).AsQueryable();
            return result.Any() ? result.OrderByProperty(queryParameters).AsPagedResults(queryParameters) : result.AsPagedResults(queryParameters);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/efilingPackageFiles")]
        public dynamic GetPackageFiles(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "package")] PackageFilesQuery package)
        {
            if (!_eFilingCompatibility.Status) throw new ConfigurationErrorsException("E-filing is not configured.");
            if (!_securityProvider.HasAccessToSubject(ApplicationSubject.EFiling)) throw new UnauthorizedAccessException();

            var result = _caseViewEfiling.GetPackageFiles(caseKey, package.ExchangeId, package.PackageSequence).AsQueryable();
            return result.ToArray();
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/efilingPackageFileData")]
        public HttpResponseMessage GetPackageFileData(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "packageFileData")] PackageFileDataQuery packageFileData)
        {
            if (!_eFilingCompatibility.Status) throw new ConfigurationErrorsException("E-filing is not configured.");
            if (!_securityProvider.HasAccessToSubject(ApplicationSubject.EFiling)) throw new UnauthorizedAccessException();

            var fileData = _caseViewEfiling.GetPackageFileData(caseKey, packageFileData.PackageSequence, packageFileData.PackageFileSequence, packageFileData.ExchangeId);
            if (fileData == null) return Request.CreateResponse(HttpStatusCode.NotFound);

            var fileType = fileData.FileType.ToLower();
            if (string.IsNullOrWhiteSpace(fileType))
            {
                fileData.FileName = fileData.FileName.TrimEnd('.');
            }
            var data = fileType == "zip" ? new MemoryStream(fileData.FileData) : _efilingFileViewer.OpenFileFromZip(fileData.FileData, fileData.FileName);
            if (data == null) return Request.CreateResponse(HttpStatusCode.NotFound);

            var result = Request.CreateResponse(HttpStatusCode.OK);
            result.Content = new StreamContent(data);
            result.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment") { FileName = fileData.FileName };
            result.Headers.Add("x-filename", fileData.FileName);
            result.Headers.Add("x-filetype", fileData.FileType);

            var isImageType = KnownFileExtensions.ImageTypes.Contains(fileType);
            var isRecognizedType = isImageType || KnownFileExtensions.EfilingTypes.Contains(fileType);
            result.Content.Headers.ContentType = isRecognizedType
                ? new MediaTypeHeaderValue($"{(isImageType ? "image" : "application")}/{fileType}")
                : new MediaTypeHeaderValue("application/octet-stream");

            return result;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/efilingHistory")]
        public PagedResults GetPackageHistory(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters, int exchangeId)
        {
            if (!_eFilingCompatibility.Status) throw new ConfigurationErrorsException("E-filing is not configured.");
            if (!_securityProvider.HasAccessToSubject(ApplicationSubject.EFiling)) throw new UnauthorizedAccessException();

            var result = _caseViewEfiling.GetPackageHistory(exchangeId).AsQueryable();
            return result.Any() ? result.OrderByProperty(queryParameters).AsPagedResults(queryParameters) : result.AsPagedResults(queryParameters);
        }

        public class PackageFilesQuery
        {
            public int ExchangeId { get; set; }
            public int PackageSequence { get; set; }
        }

        public class PackageFileDataQuery
        {
            public int? ExchangeId { get; set; }
            public int? PackageSequence { get; set; }
            public int? PackageFileSequence { get; set; }
        }
    }
}
