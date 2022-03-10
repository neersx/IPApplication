using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;

namespace Inprotech.Web.Configuration.KeepOnTopNotes
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/kottexttypes/name")]
    [RequiresAccessTo(ApplicationTask.MaintainKeepOnTopNotesNameType)]
    public class KeepOnTopNameTextTypeController : ApiController
    {
        readonly IKeepOnTopTextTypes _kotTextTypes;

        public KeepOnTopNameTextTypeController(IKeepOnTopTextTypes kotTextTypes)
        {
            _kotTextTypes = kotTextTypes;
        }

        [HttpGet]
        [Route("")]
        public dynamic GetKeepOnTopNameTextTypes(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] KeepOnTopSearchOptions searchOptions,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters qp)
        {
            var queryParameters = qp ?? new CommonQueryParameters();
            var results = _kotTextTypes.GetKotTextTypes(KnownKotTypes.Name, searchOptions).AsQueryable();

            return results.OrderBy(_ => _.TextType)
                          .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                          .Skip(queryParameters.Skip.GetValueOrDefault())
                          .ToArray();
        }

        [HttpGet]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainKeepOnTopNotesNameType)]
        public async Task<KotTextTypeData> GetKeepOnTopTextTypeNameDetails(int id)
        {
            return await _kotTextTypes.GetKotTextTypeDetails(id, KnownKotTypes.Name);
        }

        [HttpPost]
        [Route("save")]
        [RequiresAccessTo(ApplicationTask.MaintainKeepOnTopNotesCaseType)]
        public async Task<KotSaveResponse> SaveKeepOnTopNameTextType(KotTextTypeData kot)
        {
            return await _kotTextTypes.SaveKotTextType(kot, KnownKotTypes.Name);
        }

        [HttpDelete]
        [Route("delete/{id}")]
        public async Task<DeleteResponse> DeleteKeepOnTopTextType(int id)
        {
            return await _kotTextTypes.DeleteKotTextType(id);
        }
    }
}