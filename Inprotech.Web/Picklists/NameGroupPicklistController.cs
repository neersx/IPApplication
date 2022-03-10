using System;
using System.ComponentModel;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists")]
    public class NameGroupPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _queryParameters;

        public NameGroupPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _queryParameters = new CommonQueryParameters
            {
                SortBy = "title",
                SortDir = "asc"
            };
        }

        [HttpGet]
        [Route("namegroup")]
        public PagedResults<NameGroupPicklistItem> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                    CommonQueryParameters queryParameters = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            var query = search ?? string.Empty;
            var culture = _preferredCultureResolver.Resolve();

            var interimResult = _dbContext.Set<NameFamily>().Select(_ => new NameGroupPicklistItem
            {
                Key = _.Id,
                Title = DbFuncs.GetTranslation(_.FamilyTitle, null, _.FamilyTitleTid, culture),
                Comments = DbFuncs.GetTranslation(_.FamilyComments, null, _.FamilyCommentsTid, culture) ?? string.Empty
            });

            var results = interimResult.ToArray().Where(_ => _.Title.ToString().IndexOf(query, StringComparison.InvariantCultureIgnoreCase) > -1 ||
                                       _.Comments.IndexOf(query, StringComparison.InvariantCultureIgnoreCase) > -1);
            
            return results.AsOrderedPagedResults(extendedQueryParams);
        }
    }

    public class NameGroupPicklistItem
    {
        [PicklistKey]
        public int Key { get; set; }

        [PicklistDescription]
        [DisplayName(@"Title")]
        public string Title { get; set; }

        [DisplayName(@"Comments")]
        public string Comments { get; set; }
    }
}
