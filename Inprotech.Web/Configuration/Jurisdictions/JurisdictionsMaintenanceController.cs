using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainJurisdiction)]
    [RequiresAccessTo(ApplicationTask.ViewJurisdiction)]
    [RoutePrefix("api/configuration/jurisdictions")]

    public class JurisdictionsMaintenanceController : ApiController
    {
        readonly IJurisdictionSearch _jurisdictionSearch;
        readonly ICommonQueryService _commonQueryService;
        readonly IJurisdictionDetails _jurisdictionDetails;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IJurisdictionMaintenance _jurisdictionMaintenance;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISqlHelper _sqlHelper;

        public JurisdictionsMaintenanceController(IJurisdictionSearch jurisdictionSearch, ICommonQueryService commonQueryService, IJurisdictionDetails jurisdictionDetails, ITaskSecurityProvider taskSecurityProvider, IJurisdictionMaintenance jurisdictionMaintenance, ISqlHelper sqlHelper, IPreferredCultureResolver preferredCultureResolver)
        {
            _jurisdictionSearch = jurisdictionSearch;
            _commonQueryService = commonQueryService;
            _jurisdictionDetails = jurisdictionDetails;
            _taskSecurityProvider = taskSecurityProvider;
            _jurisdictionMaintenance = jurisdictionMaintenance;
            _sqlHelper = sqlHelper;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route("view")]
        [NoEnrichment]
        public dynamic InitialView()
        {
            return new
                   {
                       CanMaintain = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainJurisdiction, ApplicationTaskAccessLevel.Execute),
                       ViewOnly = _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewJurisdiction, ApplicationTaskAccessLevel.Execute)
                   };
        }

        [HttpGet]
        [Route("taxexemptoptions")]
        [NoEnrichment]
        public dynamic TaxExemptOptions()
        {
            return _jurisdictionDetails.TaxExemptOptions();
        }

        [HttpGet]
        [Route("maintenance/dayofweek/{dateString}")]
        [NoEnrichment]
        public dynamic DayOfWeek(string dateString)
        {
            var date = Convert.ToDateTime(dateString);
            return _jurisdictionDetails.DayOfWeek(date);
        }

        [HttpGet]
        [Route("search")]
        public dynamic GetSearch(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            var results = _commonQueryService.Filter(_jurisdictionSearch.Search(searchOptions), queryParameters)
                .AsQueryable();

            if (queryParameters.GetAllIds)
                return results.AsEnumerable()
                    .OrderByDescending(_ => string.Equals(_.Id, searchOptions.Text, StringComparison.InvariantCultureIgnoreCase))
                    .ThenByDescending(_ => string.Equals(_.Name, searchOptions.Text, StringComparison.InvariantCultureIgnoreCase))
                    .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                    .Select(_ => _.Id).ToArray();

            var data =
                results.AsEnumerable()
                    .Select(_ => new
                    {
                        _.Id,
                        _.Name,
                        Type = KnownJurisdictionTypes.GetType(_.Type)
                    })
                    .OrderByDescending(_ => string.Equals(_.Id, searchOptions.Text, StringComparison.InvariantCultureIgnoreCase))
                    .ThenByDescending(_ => string.Equals(_.Name, searchOptions.Text, StringComparison.InvariantCultureIgnoreCase))
                    .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                    .Skip(queryParameters.Skip.GetValueOrDefault())
                    .Take(queryParameters.Take.GetValueOrDefault())
                    .ToArray();
            
            return new PagedResults(data, results.Count());
        }

        [HttpGet]
        [Route("maintenance/days/{id}")]
        [NoEnrichment]
        public PagedResults GetHolidays(string id, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException("id");
            
            if (string.IsNullOrWhiteSpace(queryParameters.SortBy))
            {
                queryParameters.SortBy = "HolidayDate";
            }

            var holidays =_jurisdictionDetails.GetHolidays(id).ToArray();

            var cultureInfo = new System.Globalization.CultureInfo(_preferredCultureResolver.Resolve());

            var data = holidays
                .Select(v => new
                {
                    v.Id,
                    Holiday = v.HolidayName,
                    DayOfWeek = cultureInfo.DateTimeFormat.GetDayName(v.HolidayDate.DayOfWeek),
                    v.HolidayDate,
                    v.CountryId
                })
                .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                .Skip(queryParameters.Skip.GetValueOrDefault())
                .Take(queryParameters.Take.GetValueOrDefault())
                .ToArray();
            return new PagedResults(data, holidays.Length){ Ids = holidays.Select(_ => _.Id).ToArray()};
        }

        [HttpGet]
        [Route("maintenance/days/{id}/{holidayId}")]
        [NoEnrichment]
        public dynamic GetHolidayById(string id, int holidayId)
        {
            if (id == null) throw new ArgumentNullException(nameof(id));
            if (holidayId <= 0) throw new ArgumentOutOfRangeException(nameof(holidayId));

            return _jurisdictionDetails.GetHolidayById(id,holidayId);
        }

        [HttpPost]
        [Route("maintenance/changecode")]
        public dynamic UpdateJurisdictionCode(ChangeJurisdictionCodeDetails changeJurisdictionCodeDetails)
        {
            return _jurisdictionMaintenance.UpdateJurisdictionCode(changeJurisdictionCodeDetails);
        }

        [HttpGet]
        [Route("filterData/{field}")]
        public IEnumerable<object> GetFilterDataForColumn(string field,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] SearchOptions filter)
        {
            var result = _jurisdictionSearch.Search(filter);
            return GetFilterData(result);
        }

        [HttpGet]
        [Route("maintenance/{id}")]
        public dynamic GetOverview(string id)
        {
            if (id == null) throw new ArgumentNullException("id");
            return _jurisdictionDetails.GetOverview(id);
        }

        [HttpGet]
        [Route("maintenance/groups/{id}")]
        public dynamic GetGroups(string id, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException("id");
            return _jurisdictionDetails.GetGroups(id, queryParameters);
        }

        [HttpGet]
        [Route("maintenance/members/{id}")]
        public dynamic GetMembers(string id, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException("id");
            return _jurisdictionDetails.GetMembers(id, queryParameters);
        }

        [HttpGet]
        [Route("maintenance/attributes/{id}")]
        public dynamic GetAttributes(string id, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException("id");
            return _jurisdictionDetails.GetAttributes(id, queryParameters);
        }

        [HttpGet]
        [Route("maintenance/texts/{id}")]
        public dynamic GetTexts(string id, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException("id");
            return _jurisdictionDetails.GetTexts(id, queryParameters);
        }

        [HttpGet]
        [Route("maintenance/statusflags/{id}")]
        public dynamic GetStatusFlags(string id, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException("id");
            return _jurisdictionDetails.GetStatusFlags(id, queryParameters);
        }

        [HttpGet]
        [Route("maintenance/states/{id}")]
        public dynamic GetStates(string id, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException("id");
            return _jurisdictionDetails.GetStates(id, queryParameters);
        }

        [HttpGet]
        [Route("maintenance/validnumbers/{id}")]
        public dynamic GetValidNumbers(string id, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException("id");
            return _jurisdictionDetails.GetValidNumbers(id, queryParameters);
        }

        [HttpGet]
        [Route("maintenance/combinations/{id}")]
        public dynamic GetValidCombinations(string id)
        {
            if (id == null) throw new ArgumentNullException(nameof(id));
            return _jurisdictionDetails.GetValidCombinations(id);
        }

        [HttpGet]
        [Route("maintenance/classes/{id}")]
        public dynamic GetClasses(string id, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException("id");
            return _jurisdictionDetails.GetClasses(id, queryParameters);
        }

        [HttpPut]
        [Route("maintenance/{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainJurisdiction)]
        public dynamic UpdateJurisdiction(string id, JurisdictionModel formData)
        {
            if (id == null) throw new ArgumentNullException(nameof(id));
            return _jurisdictionMaintenance.Save(formData, Operation.Update);
        }

        [HttpPost]
        [Route("maintenance")]
        [RequiresAccessTo(ApplicationTask.MaintainJurisdiction)]
        public dynamic AddJurisdiction(JurisdictionModel formData)
        {
            return _jurisdictionMaintenance.Save(formData, Operation.Add);
        }

        [HttpPost]
        [Route("maintenance/delete")]
        [RequiresAccessTo(ApplicationTask.MaintainJurisdiction)]
        public dynamic DeleteJurisdiction(IEnumerable<string> ids)
        {
            return _jurisdictionMaintenance.Delete(ids);
        }

        [HttpGet]
        [Route("maintenance/validnumbers/validatestoredproc/{storedProcName}")]
        [RequiresAccessTo(ApplicationTask.MaintainJurisdiction)]
        public bool ValidateName(string storedProcName)
        {
            return _sqlHelper.IsValidProcedureName(storedProcName);
        }

        static IEnumerable<object> GetFilterData(IEnumerable<Country> source)
        {
            var r = source
                .Select(_ => new { Code = _.Type, Description = KnownJurisdictionTypes.GetType(_.Type) })
                .Distinct();

            return r.OrderBy(_ => _.Code == "2").ThenBy(_ => _.Description);
        }
    }
}
