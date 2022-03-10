using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Configuration.KeepOnTopNotes
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/kottexttypes/case")]
    [RequiresAccessTo(ApplicationTask.MaintainKeepOnTopNotesCaseType)]
    public class KeepOnTopCaseTextTypeController : ApiController
    {
        readonly IKeepOnTopTextTypes _kotTextTypes;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public KeepOnTopCaseTextTypeController(IKeepOnTopTextTypes kotTextTypes, ITaskSecurityProvider taskSecurityProvider)
        {
            _kotTextTypes = kotTextTypes;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("")]
        public dynamic GetKeepOnTopCaseTextTypes(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] KeepOnTopSearchOptions searchOptions,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters qp)
        {
            var queryParameters = qp ?? new CommonQueryParameters();
            var results = _kotTextTypes.GetKotTextTypes(KnownKotTypes.Case, searchOptions).AsQueryable();

            return results.OrderBy(_ => _.TextType)
                          .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                          .Skip(queryParameters.Skip.GetValueOrDefault())
                          .ToArray();
        }

        [HttpGet]
        [Route("permissions")]
        public dynamic GetKeepOnTopTextTypesPermissions()
        {
            return new
            {
                MaintainKeepOnTopNotesCaseType = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainKeepOnTopNotesCaseType, ApplicationTaskAccessLevel.Execute),
                MaintainKeepOnTopNotesNameType = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainKeepOnTopNotesNameType, ApplicationTaskAccessLevel.Execute)
            };
        }

        [HttpGet]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainKeepOnTopNotesCaseType)]
        public async Task<KotTextTypeData> GetKeepOnTopTextTypeCaseDetails(int id)
        {
            return await _kotTextTypes.GetKotTextTypeDetails(id, KnownKotTypes.Case);
        }

        [HttpPost]
        [Route("save")]
        public async Task<KotSaveResponse> SaveKeepOnTopCaseTextType(KotTextTypeData kot)
        {
            return await _kotTextTypes.SaveKotTextType(kot, KnownKotTypes.Case);
        }

        [HttpDelete]
        [Route("delete/{id}")]
        public async Task<DeleteResponse> DeleteKeepOnTopTextType(int id)
        {
            return await _kotTextTypes.DeleteKotTextType(id);
        }

    }

    public class KotSaveResponse
    {
        public ValidationError Error { get; set; }
        public int? Id { get; set; }
    }

    public class DeleteResponse
    {
        public string Result { get; set; }
    }
}