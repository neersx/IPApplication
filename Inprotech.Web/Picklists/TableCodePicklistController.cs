using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/tablecodes")]
    public class TableCodePicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ITableCodePicklistMaintenance _tableCodePicklistMaintenance;
        readonly CommonQueryParameters _queryParameters;

        public TableCodePicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ITableCodePicklistMaintenance tableCodePicklistMaintenance)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _tableCodePicklistMaintenance = tableCodePicklistMaintenance;
            _queryParameters = new CommonQueryParameters {SortBy = "Value"};
        }

        [HttpGet]
        [Route]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                   CommonQueryParameters queryParameters = null, string search = "",
                                   string tableType = "", string userCode = "")
        {
            var matchingType = TableTypeHelper.MatchingType(tableType);

            var culture = _preferredCultureResolver.Resolve();

            var useOffice = _dbContext.Set<TableType>().Any(_ => _.Id == matchingType && _.DatabaseTable.ToUpper().Equals("OFFICE"));
            IQueryable<TableCodeItem> list;
            if (useOffice)
            {
                list = _dbContext.Set<InprotechKaizen.Model.Cases.Office>().Select(_ => new TableCodeItem
                {
                    Id = _.Id,
                    Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                    UserCode = _.UserCode,
                    TypeId = matchingType
                });
            }
            else
            {
                list = _dbContext.Set<TableCode>()
                                 .Where(_ => _.TableTypeId == matchingType)
                                 .Select(_ => new TableCodeItem {Id = _.Id, Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture), UserCode = _.UserCode, TypeId = _.TableTypeId});
            }

            if (!string.IsNullOrEmpty(search))
                list = list.Where(_ => _.Name.Contains(search));

            if (!string.IsNullOrWhiteSpace(userCode) && userCode == "C" || userCode == "N")
                list = list.Where(_ => _.UserCode == userCode);

            list = list.OrderBy(_ => _.Name);

            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var results = Helpers.GetPagedResults(list.Select(_ => new TableCodePicklistItem
                                                  {
                                                      Key = _.Id,
                                                      Value = _.Name,
                                                      Code = _.UserCode,
                                                      TypeId = _.TypeId
                                                  }).ToArray(),
                                                  extendedQueryParams,
                                                  null, x => x.Value, search);

            results.Ids = results.Data.Select(_ => _.Key).ToArray();

            return results;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(TableCodePicklistItem), ApplicationTask.MaintainLists)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route("{id}")]
        public dynamic TableCode(int id)
        {
            var culture = _preferredCultureResolver.Resolve();

            var data = _dbContext
                       .Set<TableCode>()
                       .Where(_ => _.Id == id)
                       .Select(
                               _ => new
                               {
                                   Data = new
                                   {
                                       Key = _.Id,
                                       Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                       Code = _.UserCode ?? string.Empty,
                                       TypeId = _.TableTypeId
                                   }
                               }).SingleOrDefault();

            if (data == null)
                throw Exceptions.NotFound("No matching item found");

            return data;
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainLists, ApplicationTaskAccessLevel.Modify)]
        public dynamic Update(int id, TableCodePicklistItem tableCode)
        {
            if (tableCode == null) throw new ArgumentNullException(nameof(tableCode));

            return _tableCodePicklistMaintenance.Update(tableCode);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainLists, ApplicationTaskAccessLevel.Create)]
        public dynamic AddOrDuplicate(TableCodePicklistItem tableCode)
        {
            if (tableCode == null) throw new ArgumentNullException(nameof(tableCode));
            return _tableCodePicklistMaintenance.Add(tableCode);
        }

        [HttpDelete]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainLists, ApplicationTaskAccessLevel.Delete)]
        public dynamic Delete(int id)
        {
            return _tableCodePicklistMaintenance.Delete(id);
        }

        public class TableCodeItem
        {
            public int Id { get; set; }
            public string Name { get; set; }

            public string UserCode { get; set; }

            public short TypeId { get; set; }
        }

        public class TableCodePicklistItem
        {
            [PicklistKey]
            [PreventCopy]
            public int Key { get; set; }

            [PicklistDescription]
            [PicklistCode]
            [PicklistColumn]
            [DisplayOrder(2)]
            public string Code { get; set; }

            [PicklistDescription]
            [PicklistColumn]
            [DisplayOrder(1)]
            public string Value { get; set; }

            public short TypeId { get; set; }

            public string Type { get; set; }
        }
    }
}