using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Configuration.RecordalType
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/recordaltypes")]
    [RequiresAccessTo(ApplicationTask.MaintainRecordalType, ApplicationTaskAccessLevel.None)]
    public class RecordalTypeController : ApiController
    {
        readonly IRecordalTypes _recordalTypes;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public RecordalTypeController(IRecordalTypes recordalTypes, ITaskSecurityProvider taskSecurityProvider)
        {
            _recordalTypes = recordalTypes;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            return new
            {
                CanAdd = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRecordalType, ApplicationTaskAccessLevel.Create),
                CanDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRecordalType, ApplicationTaskAccessLevel.Delete),
                CanEdit = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRecordalType, ApplicationTaskAccessLevel.Modify)
            };
        }

        [HttpGet]
        [Route("")]
        public async Task<IEnumerable<RecordalTypeItems>> GetRecordalTypes(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters qp)
        {
            var queryParameters = qp ?? new CommonQueryParameters();

            var results = await _recordalTypes.GetRecordalTypes();

            if (!string.IsNullOrEmpty(searchOptions?.Text))
            {
                results = results.Where(_ => _.RecordalType.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            return results.OrderBy(_ => _.RecordalType)
                          .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                          .Skip(queryParameters.Skip.GetValueOrDefault())
                          .ToArray();
        }

        [Route("{id}")]
        public async Task<RecordalTypeModel> GetRecordalTypeFormById(int id)
        {
            return await _recordalTypes.GetRecordalTypeForm(id);
        }

        [HttpPost]
        [Route("submit")]
        [RequiresAccessTo(ApplicationTask.MaintainRecordalType, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> SubmitRecordalType(RecordalTypeRequest model)
        {
            return await _recordalTypes.SubmitRecordalTypeForm(model);
        }

        [HttpGet]
        [Route("elements")]
        public async Task<dynamic> GetAllElements()
        {
            return await _recordalTypes.GetAllElements();
        }

        [HttpGet]
        [Route("element/{id}")]
        public async Task<RecordalElementsModel> GetRecordalElementFormById(int id)
        {
            return await _recordalTypes.GetRecordalElementForm(id);
        }

        [HttpDelete]
        [Route("delete/{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainRecordalType, ApplicationTaskAccessLevel.Delete)]
        public async Task<dynamic> DeleteRecordalType(int id)
        {
            return await _recordalTypes.Delete(id);
        }
    }
}
