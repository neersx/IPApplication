using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;

namespace Inprotech.Web.Configuration.Jurisdictions
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainJurisdiction)]
    [RequiresAccessTo(ApplicationTask.ViewJurisdiction)]
    [RoutePrefix("api/configuration/jurisdictions/holidays")]
    public class CountryHolidayMaintenanceController : ApiController
    {

        readonly ICountryHolidayMaintenance _countryHolidayMaintenance;
        public CountryHolidayMaintenanceController(ICountryHolidayMaintenance countryHolidayMaintenance)
        {
            _countryHolidayMaintenance = countryHolidayMaintenance;
        }

        [HttpPost]
        [Route("delete")]
        public bool Delete(ICollection<CountryHolidayMaintenanceModel> deleted)
        {
            if (!deleted.Any()) return false;
            return _countryHolidayMaintenance.Delete(deleted);
        }

        [HttpPost]
        [Route("save")]
        public bool Save(CountryHolidayMaintenanceModel save)
        {
            if (save == null) throw new ArgumentNullException(nameof(save));
            return _countryHolidayMaintenance.Save(save);
        }

        [HttpGet]
        [Route("duplicate")]
        public bool IsDuplicate([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]CountryHolidayMaintenanceModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            return _countryHolidayMaintenance.IsDuplicate(model);
        }
    }
}
