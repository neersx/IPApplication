using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;

namespace Inprotech.Web.KeepOnTopNotes
{
    [Authorize]
    [RoutePrefix("api/keepontopnotes")]
    public class KeepOnTopNotesController : ApiController
    {
        readonly IKeepOnTopNotesView _keepOnTopPanelView;
        public KeepOnTopNotesController(IKeepOnTopNotesView keepOnTopPanelView)
        {
            _keepOnTopPanelView = keepOnTopPanelView;
        }

        [HttpGet]
        [Route("{caseId}/{program}")]
        [RequiresCaseAuthorization(PropertyName = "caseId")]
        public async Task<dynamic> GetKotNotesForCase(int caseId, string program)
        {
            if (string.IsNullOrEmpty(program))
            {
                program = KnownKotModules.Case;
            }
            return await _keepOnTopPanelView.GetKotNotesForCase(caseId, program);
        }

        [HttpGet]
        [Route("name/{nameId}/{program}")]
        [RequiresNameAuthorization(PropertyName = "nameId")]
        public async Task<dynamic> GetKotNotesForName(int nameId, string program)
        {
            if (string.IsNullOrEmpty(program))
            {
                program = KnownKotModules.Name;
            }
            return await _keepOnTopPanelView.GetKotNotesForName(nameId, program);
        }
    }

    public enum KotProgram
    {
        Case = 1,
        Name = 2,
        Billing = 4,
        Time = 8,
        TaskPlanner = 16
    }
}
