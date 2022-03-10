using System;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases;

namespace Inprotech.Web.Cases
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class GoodsServicesController : ApiController
    {
        readonly ICaseTextResolver _caseTextResolver;

        public GoodsServicesController(ICaseTextResolver caseTextResolver)
        {
            _caseTextResolver = caseTextResolver;
        }

        [HttpGet]
        [Route("{caseId:int}/goods-services-text/class/{classKey}/language/{languageCode:int?}")]
        [RequiresCaseAuthorization]
        public async Task<string> GoodsServicesText(int caseId, string classKey, int? languageCode = null)
        {
            if (string.IsNullOrEmpty(classKey)) throw new ArgumentNullException(nameof(classKey));

            return await _caseTextResolver.GetCaseText(caseId, KnownTextTypes.GoodsServices, classKey, languageCode);
        }
    }
}
