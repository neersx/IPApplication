using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/dataItemGroup")]
    public class DataItemGroupPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDataItemGroupPicklistMaintenance _dataItemGroupPicklistMaintenance;

        public DataItemGroupPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver , IDataItemGroupPicklistMaintenance dataItemGroupPicklistMaintenance)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _dataItemGroupPicklistMaintenance = dataItemGroupPicklistMaintenance ?? throw new ArgumentException(nameof(dataItemGroupPicklistMaintenance));

            _queryParameters = new CommonQueryParameters { SortBy = "Value" };
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(DataItemGroup), ApplicationTask.MaintainDataItems)]
        [PicklistMaintainabilityActions(allowDuplicate: false)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(DataItemGroup), ApplicationTask.MaintainDataItems)]
        public PagedResults DataItemGroups([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var all = MatchingItems(search);

            var result = Helpers.GetPagedResults(all, extendedQueryParams, x => x.Code.ToString(), x => x.Value, search);

            return result;
        }

        [HttpGet]
        [Route("{code}")]
        [PicklistPayload(typeof(DataItemGroup), ApplicationTask.MaintainDataItems)]
        public DataItemGroup DataItemGroup(int code)
        {
            var dataItem = _dbContext.Set<Group>().SingleOrDefault(_ => _.Code == code);
            if (dataItem == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.DataItemGroupDoesNotExist.ToString());

            return dataItem != null ? new DataItemGroup(dataItem.Code, dataItem.Name) : null;
        }

        IEnumerable<DataItemGroup> MatchingItems(string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();

            var interim = _dbContext.Set<Group>().Select(_ => new DataItemGroup
            {
                Code = _.Code,
                Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
            });

            var result = interim.AsEnumerable();

            if (!string.IsNullOrEmpty(search))
            {
                result = result.Where(_ => _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            return result;
        }

        [HttpPost]
        [Route]
        public dynamic Add(DataItemGroup dataItemGroup)
        {
            if (dataItemGroup == null) throw new ArgumentNullException(nameof(dataItemGroup));

            return _dataItemGroupPicklistMaintenance.Save(dataItemGroup, Operation.Add);
        }

        [HttpPut]
        [Route("{code}")]
        public dynamic Update(string code, DataItemGroup dataItemGroup)
        {
            if (dataItemGroup == null) throw new ArgumentNullException(nameof(dataItemGroup));

            return _dataItemGroupPicklistMaintenance.Save(dataItemGroup, Operation.Update);
        }

        [HttpDelete]
        [Route("{code}")]
        public dynamic Delete(int code)
        {
            return _dataItemGroupPicklistMaintenance.Delete(code);
        }
    }

    public class DataItemGroup
    {
        public DataItemGroup() { }

        public DataItemGroup(int code, string description)
        {
            Code = code;
            Value = description;
        }

        [PicklistKey]
        public int Key => Code;

        [PicklistCode]
        public int Code { get; set; }

        [PicklistDescription]
        [DisplayOrder(0)]
        [Required]
        [MaxLength(40)]
        public string Value { get; set; }
    }
}
