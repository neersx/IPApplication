using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.QuickCaseSearch)]
    [RoutePrefix("api/quickSearch")]
    public class QuickSearchController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IDbContext _dbContext;

        public QuickSearchController(ISecurityContext securityContext, IDbContext dbContext)
        {
            _securityContext = securityContext;
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("typeahead")]
        [NoEnrichment]
        public IEnumerable<QuickSearchPicklistItem> TypeAhead(string q)
        {
            if (string.IsNullOrWhiteSpace(q))
            {
                return null;
            }
            return _dbContext.QuickSearchPicklist(q, _securityContext.User.Id, 10)
                             .Select(FormatPicklistItem);
        }

        QuickSearchPicklistItem FormatPicklistItem(QuickSearchPicklistItem item)
        {
            if (item.Using == "Case Ref")
            {
                item.MatchedOn = null;
                item.Using = null;
            }

            return item;
        }
    }
}