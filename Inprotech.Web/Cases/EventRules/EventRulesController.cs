using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Cases.EventRules.Models;

namespace Inprotech.Web.Cases.EventRules
{
    [Authorize]
    [RoutePrefix("api/case/eventRules")]
    [RequiresAccessTo(ApplicationTask.ViewRuleDetails)]
    public class EventRulesController : ApiController
    {
        readonly IEventRulesService _eventRulesService;

        public EventRulesController(IEventRulesService evenEventRulesService)
        {
            _eventRulesService = evenEventRulesService;
        }

        [HttpGet]
        [Route("getEventRulesDetails")]
        [RequiresCaseAuthorization(PropertyPath = "q.CaseId")]
        [NoEnrichment]
        public dynamic GetEventRulesDetails([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                            EventRulesModel.EventRulesRequest q = null)
        {
            if (q == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            return _eventRulesService.GetEventRulesDetails(q);
        }
    }
}
