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
    public class DesignElementsController : ApiController
    {
        readonly IDesignElements _designElements;

        public DesignElementsController(
            IDesignElements designElements)
        {
            _designElements = designElements;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/designElements")]
        public PagedResults GetDesignElements(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp = null)
        {
            var queryParameters = qp ?? new CommonQueryParameters();

            var elements = _designElements.GetCaseDesignElements(caseKey);
            var elementsData = elements.AsQueryable().OrderByProperty(queryParameters)
                                       .AsPagedResults(queryParameters);

            return new PagedResults(elementsData.Data, elementsData.Pagination.Total);
        }

        [HttpPost]
        [RequiresCaseAuthorization(PropertyPath = "request.CaseKey")]
        [Route("designElements/validate")]
        public IEnumerable<ValidationError> ValidateDesignElements([FromBody] DesignElementValidateRequest request)
        {
            return _designElements.ValidateDesignElements(request.CaseKey, request.CurrentRow, request.ChangedRows);
        }
    }

    public class DesignElementValidateRequest
    {
        public int CaseKey { get; set; }
        public DesignElementData CurrentRow { get; set; }
        public IEnumerable<DesignElementData> ChangedRows { get; set; }
    }
}
