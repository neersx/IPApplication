using System;
using System.ComponentModel;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/searchgroup")]
    public class SearchGroupPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISearchGroupPicklistMaintenance _searchGroupPicklistMaintenance;

        public SearchGroupPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ISearchGroupPicklistMaintenance searchGroupPicklistMaintenance)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _searchGroupPicklistMaintenance = searchGroupPicklistMaintenance;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(SearchGroupData), ApplicationTask.MaintainPublicSearch)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(SearchGroupData), ApplicationTask.MaintainPublicSearch)]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "",
                                   int? queryContext = null)
        {
            if (queryContext == null)
                throw new ArgumentNullException(nameof(queryContext));

            var culture = _preferredCultureResolver.Resolve();

            var queryGroups = _dbContext.Set<QueryGroup>().Where(_ => _.ContextId == queryContext.Value).AsQueryable();

            var result = queryGroups.Select(_ => new SearchGroupData
            {
                Key = _.Id.ToString(),
                Value = DbFuncs.GetTranslation(_.GroupName, null, _.GroupName_Tid, culture),
                ContextId = queryContext
            }).OrderBy(_ => _.Value).ToArray();

            if (!string.IsNullOrWhiteSpace(search))
            {
                result = result.Where(_ => _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0).ToArray();
            }

            return Helpers.GetPagedResults(result,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Key, x => x.Value, search);
        }

        [HttpPut]
        [Route("{Id}")]
        [RequiresAccessTo(ApplicationTask.MaintainPublicSearch)]
        public dynamic Update(int id, QueryGroup queryGroup)
        {
            if (queryGroup == null) throw new ArgumentNullException(nameof(queryGroup));
            queryGroup.Id = id;
            return _searchGroupPicklistMaintenance.Save(queryGroup, Operation.Update);
        }

        [HttpGet]
        [Route("{id}")]
        [PicklistPayload(typeof(SearchGroupData), ApplicationTask.MaintainPublicSearch)]
        public SearchGroupData SearchMenuGroup(int id)
        {
            var querySearchGroup = _dbContext.Set<QueryGroup>()
                                              .SingleOrDefault(_ => _.Id == id);
            if (querySearchGroup == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var result = new SearchGroupData
            {
                Key = querySearchGroup.Id.ToString(),
                Value = querySearchGroup.GroupName,
                ContextId = querySearchGroup.ContextId
            };

            return result;
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainPublicSearch)]
        public dynamic AddOrDuplicate(QueryGroup queryGroup)
        {
            if (queryGroup == null) throw new ArgumentNullException(nameof(queryGroup));
            var count = _dbContext.Set<QueryGroup>().ToList().Max(x => x.DisplaySequence).Value + 1;
            queryGroup.DisplaySequence = Convert.ToInt16(count);
            return _searchGroupPicklistMaintenance.Save(queryGroup, Operation.Add);
        }

        [HttpDelete]
        [Route("{Id}")]
        public dynamic Delete(int id)
        {
            return _searchGroupPicklistMaintenance.Delete(id);
        }
    }

    public class SearchGroupData
    {
        [PicklistKey]
        public string Key { get; set; }

        [DisplayName("description")]
        [DisplayOrder(1)]
        public string Value { get; set; }

        public int? ContextId { get; set; }
    }
}