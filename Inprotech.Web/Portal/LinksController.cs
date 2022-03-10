using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;

namespace Inprotech.Web.Portal
{
    [Authorize]
    [RoutePrefix("api/portal")]
    public class LinksController : ApiController
    {
        readonly ILinksResolver _linksResolver;

        public LinksController(ILinksResolver linksResolver)
        {
            _linksResolver = linksResolver;
        }

        [HttpGet]
        [NoEnrichment]
        [Route("links")]
        public async Task<IEnumerable<LinksViewModel>> GetLinks()
        {
            return await _linksResolver.Resolve();
        }
    }

    public class LinksViewModel
    {
        public LinksViewModel()
        {
            Links = new Collection<LinksModel>();
        }

        public string Group { get; set; }

        public ICollection<LinksModel> Links { get; set; }
    }

    public class LinksModel
    {
        public string Title { get; set; }

        public string Tooltip { get; set; }

        public Uri Url { get; set; }

        public bool ShouldTargetBlank => new[] {Uri.UriSchemeHttp, Uri.UriSchemeHttps}.Contains(Url.Scheme);
    }
}