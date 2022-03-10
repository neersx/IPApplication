using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Picklists;

namespace Inprotech.Web.Configuration.Offices
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/offices")]
    [RequiresAccessTo(ApplicationTask.MaintainOffice, ApplicationTaskAccessLevel.None)]
    public class OfficeController : ApiController
    {
        readonly IOffices _offices;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public OfficeController(IOffices offices, ITaskSecurityProvider taskSecurityProvider)
        {
            _offices = offices;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            return new
            {
                CanAdd = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainOffice, ApplicationTaskAccessLevel.Create),
                CanDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainOffice, ApplicationTaskAccessLevel.Delete),
                CanEdit = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainOffice, ApplicationTaskAccessLevel.Modify)
            };
        }

        [HttpGet]
        [Route("")]
        public async Task<IEnumerable<Office>> GetOffices(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters qp)
        {
            var queryParameters = qp ?? new CommonQueryParameters();

            var results = await _offices.GetOffices(searchOptions.Text);
            
            return results.OrderBy(_ => _.Value)
                          .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                          .Skip(queryParameters.Skip.GetValueOrDefault())
                          .ToArray();
        }

        [HttpGet]
        [Route("printers")]
        public async Task<IEnumerable<Printer>> GetAllPrinters()
        {
            return await _offices.GetAllPrinters();
        }

        [HttpGet]
        [Route("{id:int}")]
        public async Task<OfficeData> GetOffice(int id)
        {
            return await _offices.GetOffice(id);
        }

        [HttpPost]
        [Route("")]
        
        [RequiresAccessTo(ApplicationTask.MaintainOffice, ApplicationTaskAccessLevel.Create)]
        public async Task<OfficeSaveResponse> AddOffice(OfficeData data)
        {
            if (data == null) throw new ArgumentNullException(nameof(data));
            return await _offices.SaveOffice(data);
        }

        [HttpPut]
        [Route("{id}")]
        
        [RequiresAccessTo(ApplicationTask.MaintainOffice, ApplicationTaskAccessLevel.Modify)]
        public async Task<OfficeSaveResponse> UpdateOffice(OfficeData data)
        {
            if (data == null) throw new ArgumentNullException(nameof(data));
            return await _offices.SaveOffice(data);
        }

        [HttpDelete]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainOffice, ApplicationTaskAccessLevel.Delete)]
        public async Task<DeleteResponseModel> Delete(DeleteRequestModel deleteRequestModel)
        {
            return await _offices.Delete(deleteRequestModel);
        }
    }
}
