using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
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
    [RoutePrefix("api/picklists/columngroup")]
    [RequiresAccessTo(ApplicationTask.MaintainPublicSearch)]
    public class ColumnGroupPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IColumnGroupPicklistMaintenance _columnGroupPicklistMaintenance;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Value",
                SortDir = "asc"
            });

        public ColumnGroupPicklistController(IDbContext dbContext,
                                             IPreferredCultureResolver preferredCultureResolver,
                                             IColumnGroupPicklistMaintenance columnGroupPicklistMaintenance)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _columnGroupPicklistMaintenance = columnGroupPicklistMaintenance; 
        }

        [HttpGet]
        [Route("{id}")]
        [PicklistPayload(typeof(QueryColumnGroupPayload), ApplicationTask.MaintainPublicSearch)]
        public QueryColumnGroupPayload ColumnGroup(int id)
        {
            var queryColumnGroup = _dbContext.Set<QueryColumnGroup>()
                                              .SingleOrDefault(_ => _.Id == id);
            if(queryColumnGroup == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var result = new QueryColumnGroupPayload
            {
                Key = queryColumnGroup.Id,
                Value = queryColumnGroup.GroupName,
                ContextId = queryColumnGroup.ContextId
            };

            return result;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(QueryColumnGroupPayload), ApplicationTask.MaintainPublicSearch)]
        [PicklistMaintainabilityActions(allowDuplicate: false)]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null,
                                   string search = "",
                                   int? queryContext = null)
        {
            if (!queryContext.HasValue)
                throw new ArgumentNullException(nameof(queryContext));

            var queryParams = SortByParameters.Extend(queryParameters);

            var culture = _preferredCultureResolver.Resolve();

            var queryColumnGroups = _dbContext.Set<QueryColumnGroup>()
                                        .Where(_ => _.ContextId == queryContext);

            var result = queryColumnGroups.Select(_ => new QueryColumnGroupPayload
            {
                Key = _.Id,
                Value = DbFuncs.GetTranslation(_.GroupName, null, _.GroupNameTId, culture),
                ContextId = queryContext.Value
            }).ToArray();

            if (!string.IsNullOrWhiteSpace(search))
            {
                result = result.Where(_ => _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0).ToArray();
            }

            return Helpers.GetPagedResults(result,
                                           queryParams,
                                           x => x.Key.ToString(), x => x.Value, search);
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Update(int id, QueryColumnGroupPayload queryGroup)
        {
            if (queryGroup == null) throw new ArgumentNullException(nameof(queryGroup));

            return _columnGroupPicklistMaintenance.Save(queryGroup, Operation.Update);
        }

        [HttpPost]
        [Route]
        public dynamic AddOrDuplicate(QueryColumnGroupPayload queryGroup)
        {
            if (queryGroup == null) throw new ArgumentNullException(nameof(queryGroup));
            
            return _columnGroupPicklistMaintenance.Save(queryGroup, Operation.Add);
        }

        [HttpDelete]
        [Route("{id}")]
        public dynamic Delete(int id)
        {
            return _columnGroupPicklistMaintenance.Delete(id);
        }
    }

    public class QueryColumnGroupPayload
    {
        [PicklistKey]
        public int Key { get; set; }

        [DisplayName("description")]
        [DisplayOrder(1)]
        [Required]
        [MaxLength(50)]
        public string Value { get; set; }

        public int ContextId { get; set; }
    }
}
