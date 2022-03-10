using System;
using System.Linq;
using System.Web.Http;
using Inprotech.Web.Search.CaseSupportData;

namespace Inprotech.Web.Lists
{
    [Authorize]
    public class OfficesController : ApiController
    {
        readonly IOffices _offices;

        public OfficesController(IOffices offices)
        {
            if(offices == null) throw new ArgumentNullException("offices");
            _offices = offices;
        }

        [Route("api/lists/offices")]
        public dynamic Get(string q)
        {
            var offices = _offices.Get();
            q = q ?? string.Empty;

            return offices.Where(o => o.Value.StartsWith(q, StringComparison.OrdinalIgnoreCase))
                          .Select(o => new
                                       {
                                           o.Key,
                                           Description = o.Value
                                       })
                          .ToArray();
        }
    }
}
