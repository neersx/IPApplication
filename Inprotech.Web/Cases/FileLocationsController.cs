using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Cases
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class FileLocationsController : ApiController
    {
        readonly IFileLocations _fileLocations;
        readonly ICommonQueryService _commonQueryService;

        public FileLocationsController(
            IFileLocations fileLocations,
            ICommonQueryService commonQueryService)
        {
            _fileLocations = fileLocations;
            _commonQueryService = commonQueryService ?? throw new ArgumentNullException("commonQueryService");
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/fileLocations/{showHistory:bool}")]
        public PagedResults GetFileLocations(int caseKey, bool showHistory, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp = null)
        {
            var queryParameters = qp ?? new CommonQueryParameters();
            var data = _fileLocations.GetCaseFileLocations(caseKey, null, showHistory).AsQueryable().OrderByProperty(queryParameters);
            var r = _commonQueryService.Filter(data, queryParameters).AsPagedResults(queryParameters);
            var fileLocations = r.Items<FileLocationsData>();

            return new PagedResults(fileLocations, r.Pagination.Total);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/fileLocations")]
        public PagedResults GetFileLocationForFilePart(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp = null,
                                                       [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "filePartId")] int? filePartId = null)
        {
            var queryParameters = qp ?? new CommonQueryParameters();
            var data = _fileLocations.GetCaseFileLocations(caseKey, filePartId, false, true).AsQueryable().OrderByProperty(queryParameters);
            var r = _commonQueryService.Filter(data, queryParameters).AsPagedResults(queryParameters);
            var fileLocations = r.Items<FileLocationsData>();

            return new PagedResults(fileLocations, r.Pagination.Total);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("getCaseReference/{caseKey:int}")]
        public string GetCaseReference(int caseKey)
        {
            return _fileLocations.GetCaseReference(caseKey);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/fileLocations/filterData/{field}")]
        public IEnumerable<CodeDescription> GetFilterDataForColumn(int caseKey, string field,
                                                                   [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "columnFilters")] IEnumerable<CommonQueryParameters.FilterValue> columnFilters = null)
        {
            var qp = FileLocationQueryParameters.Get(new CommonQueryParameters
            {
                Filters = columnFilters
            });

            return _fileLocations.AllowableFilters(caseKey, field, qp);
        }

        [HttpPost]
        [RequiresCaseAuthorization(PropertyPath = "request.CaseKey")]
        [Route("fileLocations/validate")]
        public IEnumerable<ValidationError> ValidateFileLocations([FromBody] FileLocationsValidateRequest request)
        {
            if (request == null) throw new ArgumentNullException();
            return _fileLocations.ValidateFileLocations(request.CaseKey, request.CurrentRow, request.ChangedRows);
        }
    }

    public static class FileLocationQueryParameters
    {
        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "filePartDescription",
                SortDir = "asc"
            });

        public static CommonQueryParameters Get(CommonQueryParameters queryParameters)
        {
            return DefaultQueryParameters
                .Extend(queryParameters);
        }
    }

    public class FileLocationsValidateRequest
    {
        public int CaseKey { get; set; }
        public FileLocationsData CurrentRow { get; set; }
        public IEnumerable<FileLocationsData> ChangedRows { get; set; }
    }
}
