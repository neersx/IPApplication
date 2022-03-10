using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using AutoMapper;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/dataItems")]
    public class DataItemsPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDataItemMaintenance _dataItemMaintenance;
        IMapper _mapper;

        public DataItemsPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IDataItemMaintenance dataItemMaintenance)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _dataItemMaintenance = dataItemMaintenance ?? throw new ArgumentNullException(nameof(dataItemMaintenance));
            _queryParameters = new CommonQueryParameters { SortBy = "Code", SortDir = "asc" };

            ConfigureMappers();
        }

        void ConfigureMappers()
        {
            var config = new MapperConfiguration(cfg =>
            {
                cfg.CreateMap<DataItem, DataItemPayload>();
                cfg.CreateMissingTypeMaps = true;
            });

            _mapper = config.CreateMapper();
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(DataItem), ApplicationTask.MaintainDataItems)]
        [PicklistMaintainabilityActions(allowDuplicate: false)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(DataItem), ApplicationTask.MaintainDataItems)]
        [PicklistMaintainabilityActions(allowDuplicate: false)]
        public PagedResults DataItems([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var all = MatchingItems(search);
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var dataItems = all as DataItem[] ?? all.ToArray();
            var result = Helpers.GetPagedResults(dataItems, extendedQueryParams, x => x.Code.ToString(), x => x.Value, search);
            result.Ids = Helpers.GetPagedResults(dataItems, new CommonQueryParameters { SortDir = extendedQueryParams?.SortDir, SortBy = extendedQueryParams?.SortBy, Take = dataItems.Length }, x => x.Code.ToString(), x => x.Value, search)
                                .Data.Select(_ => _.Key);
            return result;
        }

        IEnumerable<DataItem> MatchingItems(string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();
            var interim = _dbContext.Set<DocItem>().Select(_ => new DataItem
            {
                Key = _.Id,
                Code = _.Name,
                Value = DbFuncs.GetTranslation(_.Description, null, _.ItemDescriptionTId, culture) ?? string.Empty,
                ItemType = _.ItemType
            });

            var result = interim.AsEnumerable();

            if (!string.IsNullOrEmpty(search))
            {
                result = result.Where(_ => _.Code.ToString().IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1 ||
                                           _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            return result.ToList();
        }

        [HttpGet]
        [Route("{dataItemId}")]
        [PicklistPayload(typeof(DataItem), ApplicationTask.MaintainDataItems)]
        public DataItem DataItem(int dataItemId)
        {
            return _dataItemMaintenance.DataItem(dataItemId, true);
        }

        [HttpDelete]
        [Route("{dataItemId}")]
        public dynamic Delete(int dataItemId)
        {
            var request = new DeleteRequestModel();
            request.Ids.Add(dataItemId);

            var response = _dataItemMaintenance.Delete(request);
            if (response.InUseIds.Any())
                return KnownSqlErrors.CannotDelete.AsHandled();

            return new
            {
                Result = "success"
            };
        }

        [HttpPost]
        [Route("validate")]
        public dynamic Validate(DataItem saveDetails)
        {
            var errors = _dataItemMaintenance.ValidateSql(new DocItem().FromSaveDetails(saveDetails), saveDetails).ToArray();
            return errors.Any() ? errors.AsErrorResponse() : null;
        }

        [HttpPost]
        [Route("")]
        public dynamic Save(DataItem saveDetails)
        {
            return _dataItemMaintenance.Save(_mapper.Map<DataItem, DataItemPayload>(saveDetails),
                                                new { Id = saveDetails.Key, Name = saveDetails.Code, Description = saveDetails.Value });
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Update(short id, DataItem saveDetails)
        {
            return _dataItemMaintenance.Update(id, _mapper.Map<DataItem, DataItemPayload>(saveDetails),
                                                new { Id = saveDetails.Key, Name = saveDetails.Code, Description = saveDetails.Value });
        }
    }

    public class DataItem : DataItemPayload
    {
        [PicklistKey]
        public int Key { get; set; }

        [PicklistCode]
        [DisplayOrder(0)]
        [DisplayName(@"Code")]
        public string Code { get; set; }

        [PicklistDescription]
        [DisplayOrder(1)]
        public string Value { get; set; }
    }
}
