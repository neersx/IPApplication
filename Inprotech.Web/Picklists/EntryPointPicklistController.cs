using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.InproDoc.Config;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/entrypoint")]
    public class EntryPointPicklistController : ApiController
    {
        readonly IPassThruManager _passThruManager;

        public EntryPointPicklistController(IPassThruManager passThruManager)
        {
            _passThruManager = passThruManager ?? throw new ArgumentNullException(nameof(passThruManager));
        }

        [HttpGet]
        [Route("search")]
        public PagedResults EntryPoints([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null,string search = "")
        {
            var entryPoints = _passThruManager.GetEntryPoints();

            if (!string.IsNullOrEmpty(search)) entryPoints = entryPoints.Where(_ => _.Name.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1
                                                                                 || _.Description.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);

            var data = entryPoints.Select(_ => new { _.Name, _.Description }).OrderByNumeric(queryParameters.SortBy, queryParameters.SortDir);
            return new PagedResults(data, data.Count());
        }
    }
}
