using System;
using System.Web.Http;
using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Lists
{
    [Authorize]
    public class PropertyTypesController : ApiController
    {
        readonly IPropertyTypes _propertyTypes;

        public PropertyTypesController(IPropertyTypes propertyTypes)
        {
            if(propertyTypes == null) throw new ArgumentNullException("propertyTypes");
            _propertyTypes = propertyTypes;
        }

        [Route("api/lists/propertyTypes")]
        public dynamic Get(string q, [FromUri]string[] countries = null)
        {
            return _propertyTypes.Get(q, countries);
        }
    }
}