using System.ComponentModel;
using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists")]
    public class ValidUsersPicklistController : ApiController
    {
        readonly IDbContext _dbContext;

        public ValidUsersPicklistController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("internalUsers")]
        public PagedResults<ValidUsersPicklistItem> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                           CommonQueryParameters queryParameters = null, string search = "")
        {
            var query = search ?? string.Empty;

            var interimResult = from u in _dbContext.Set<User>()
                                let n = (u.Name.FirstName ?? string.Empty) + (u.Name.MiddleName ?? string.Empty) + (u.Name.LastName ?? string.Empty)
                                where !u.IsExternalUser
                                      && u.IsValid
                                      && (u.UserName.Contains(query) || n.Contains(query))
                                select u;

            var results = from r in interimResult.Include(_ => _.Name).ToArray()
                          let formattedName = r.Name.Formatted()
                          let isContains = r.UserName.IgnoreCaseContains(query) || formattedName.IgnoreCaseContains(query)
                          let isStartsWith = r.UserName.IgnoreCaseStartsWith(query) || formattedName.IgnoreCaseStartsWith(query)
                          orderby isStartsWith descending, isContains descending, r.UserName
                          select new ValidUsersPicklistItem
                          {
                              Key = r.Id,
                              Username = r.UserName,
                              Name = formattedName
                          };
            
            return results.AsPagedResults(CommonQueryParameters.Default.Extend(queryParameters));
        }

        public class ValidUsersPicklistItem
        {
            [PicklistKey]
            public int Key { get; set; }

            [PicklistDescription]
            public string Username { get; set; }

            [DisplayName(@"Description")]
            public string Name { get; set; }
        }
    }
}