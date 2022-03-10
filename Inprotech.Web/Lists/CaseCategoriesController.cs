using System;
using System.Web.Http;
using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Lists
{
    [Authorize]
    public class CaseCategoriesController : ApiController
    {
        readonly ICaseCategories _caseCategories;

        public CaseCategoriesController(ICaseCategories caseCategories)
        {
            if(caseCategories == null) throw new ArgumentNullException("caseCategories");
            _caseCategories = caseCategories;
        }

        [Route("api/lists/caseCategories")]
        public dynamic Get(string q, string caseType, [FromUri]string[] countries = null, [FromUri]string[] propertyTypes = null)
        {
            return _caseCategories.Get(q, caseType, countries, propertyTypes);
        }
    }
}
