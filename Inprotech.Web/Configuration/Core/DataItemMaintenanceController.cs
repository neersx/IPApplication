using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using AutoMapper;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.SchemaMapping;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainDataItems)]
    [RoutePrefix("api/configuration/dataitems")]
    public class DataItemMaintenanceController : ApiController
    {
        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Name",
                SortDir = "asc"
            });

        readonly ICommonQueryService _commonQueryService;
        readonly IDataItemMaintenance _dataItemMaintenance;
        readonly IDbContext _dbContext;
        readonly IDocItemReader _docItemReader;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        IMapper _mapper;

        public DataItemMaintenanceController(IDbContext dbContext, IDocItemReader docItemReader,
                                             ICommonQueryService commonQueryService, IPreferredCultureResolver preferredCultureResolver, IDataItemMaintenance dataItemMaintenance)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _docItemReader = docItemReader ?? throw new ArgumentNullException(nameof(docItemReader));
            _commonQueryService = commonQueryService ?? throw new ArgumentNullException(nameof(commonQueryService));
            _dataItemMaintenance = dataItemMaintenance ?? throw new ArgumentNullException(nameof(dataItemMaintenance));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));

            ConfigureMappers();
        }

        void ConfigureMappers()
        {
            var config = new MapperConfiguration(cfg =>
            {
                cfg.CreateMap<DataItemEntity, DataItemPayload>();
                cfg.CreateMissingTypeMaps = true;
            });

            _mapper = config.CreateMapper();
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            return null;
        }

        public class DataItemSearchOptions : SearchOptions
        {
            public ICollection<DataItemGroup> Group { get; set; }

            public bool IncludeSql { get; set; }
        }

        #region Search

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                              DataItemSearchOptions searchOptions,
                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                              CommonQueryParameters queryParameters = null)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var dataItems = DoSearch(searchOptions);

            if (queryParameters.Filters.Any())
            {
                dataItems = _commonQueryService.Filter(dataItems, queryParameters)
                                               .AsQueryable();
            }

            var ids = dataItems.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir).Select(_ => new {_.Id}).ToArray();
            var count = ids.Length;

            var executedResults = dataItems.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                                           .Skip(queryParameters.Skip.GetValueOrDefault())
                                           .Take(queryParameters.Take.GetValueOrDefault());

            var culture = _preferredCultureResolver.Resolve();

            var initial = executedResults.Select(_ => new
            {
                _.Name,
                Description = DbFuncs.GetTranslation(_.Description, null, _.ItemDescriptionTId, culture),
                _.Sql,
                _.Id,
                _.ItemType,
                _.CreatedBy,
                _.DateUpdated,
                _.DateCreated,
                IsSql = _.ItemType == 0,
                Notes = _.Note != null ? _.Note.ItemNotes : string.Empty
            }).ToArray();

            var extended = initial.Select(_ => new
            {
                _.Id,
                OutputDataType = OutputDataType(_.Id),
                Groups = _dataItemMaintenance.DataItemGroups(_.Id)
            });

            var result = initial.Join(extended, arg => arg.Id, arg => arg.Id,
                                      (first, second) => new
                                      {
                                          first.Id, first.Name, first.CreatedBy, first.DateCreated, first.DateUpdated,
                                          first.Description, first.IsSql, first.ItemType, first.Notes, first.Sql,
                                          second.OutputDataType, second.Groups
                                      });

            return new
            {
                Results = new PagedResults(result, count),
                Ids = ids
            };
        }

        [HttpGet]
        [Route("{dataItemId}")]
        public DataItemEntity DataItem(int dataItemId)
        {
            return _dataItemMaintenance.DataItem(dataItemId);
        }

        IQueryable<DocItem> DoSearch(DataItemSearchOptions searchOptions)
        {
            var culture = _preferredCultureResolver.Resolve();

            var dataItems = _dbContext.Set<DocItem>().AsQueryable();

            if (searchOptions == null) return dataItems;

            var searchText = searchOptions.Text ?? string.Empty;
            var includeSql = searchOptions.IncludeSql;

            dataItems = _dbContext.Set<DocItem>()
                                  .Where(_ => _.Name.Contains(searchText) ||
                                              DbFuncs.GetTranslation(_.Description, null, _.ItemDescriptionTId, culture).Contains(searchText) ||
                                              includeSql && _.Sql.Contains(searchText));

            if (searchOptions.Group == null || !searchOptions.Group.Any()) return dataItems;
            {
                var groupIds = searchOptions.Group.Select(_ => _.Code);
                var itemGroups = _dbContext.Set<ItemGroup>().AsQueryable();
                dataItems = dataItems.Where(di => itemGroups.Where(ig => groupIds.Contains(ig.Code)).Any(_ => _.ItemId.Equals(di.Id)));
            }

            return dataItems;
        }

        string OutputDataType(int dataItemId)
        {
            var types = new List<string>();
            try
            {
                var columns = _docItemReader.Read(dataItemId).Columns;

                foreach (var type in columns) types.Add((string) type.Type);
            }
            catch
            {
                // swallowed
            }

            var result = types.Any() ? string.Join(", ", types.Select(_ => _)) : "-";
            return result;
        }

        #endregion

        #region Filters

        [HttpGet]
        [Route("filterData/{field}")]
        public IEnumerable<CodeDescription> GetFilterDataForColumn(string field,
                                                                   [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")]
                                                                   DataItemSearchOptions filter)
        {
            var result = DoSearch(filter);
            return GetFilterData(result, field);
        }

        IEnumerable<CodeDescription> GetFilterData(IQueryable<DocItem> source, string field)
        {
            switch (field)
            {
                case "createdBy":
                    return source.AsEnumerable()
                                 .OrderBy(c => c.CreatedBy)
                                 .Select(_ => _commonQueryService.BuildCodeDescriptionObject(_.CreatedBy, _.CreatedBy))
                                 .Distinct();
                case "dateCreated":
                    return source.AsEnumerable()
                                 .OrderBy(dc => dc.DateCreated)
                                 .Select(_ => _commonQueryService.BuildCodeDescriptionObject(_.DateCreated?.ToString() ?? string.Empty, _.DateCreated?.ToString() ?? string.Empty))
                                 .Distinct();
                case "dateUpdated":
                    return source.AsEnumerable()
                                 .OrderBy(du => du.DateCreated)
                                 .Select(_ => _commonQueryService.BuildCodeDescriptionObject(_.DateUpdated?.ToString() ?? string.Empty, _.DateUpdated?.ToString() ?? string.Empty))
                                 .Distinct();
            }

            return null;
        }

        #endregion

        #region Maintenance

        [HttpPost]
        [Route("")]
        public dynamic Save(DataItemEntity saveDetails)
        {
            return _dataItemMaintenance.Save(_mapper.Map<DataItemEntity, DataItemPayload>(saveDetails),
                                             new {saveDetails.Id, saveDetails.Name, saveDetails.Description});
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Update(int id, DataItemEntity saveDetails)
        {
            return _dataItemMaintenance.Update(id, _mapper.Map<DataItemEntity, DataItemPayload>(saveDetails),
                                               new {saveDetails.Id, saveDetails.Name, saveDetails.Description});
        }

        [HttpPost]
        [Route("validate")]
        public dynamic Validate(DataItemEntity saveDetails)
        {
            var errors = _dataItemMaintenance.ValidateSql(new DocItem().FromSaveDetails(saveDetails), saveDetails).ToArray();
            return errors.Any() ? errors.AsErrorResponse() : null;
        }

        [HttpPost]
        [Route("delete")]
        [NoEnrichment]
        public DeleteResponseModel Delete(DeleteRequestModel deleteRequestModel)
        {
            return _dataItemMaintenance.Delete(deleteRequestModel);
        }

        #endregion
    }
}