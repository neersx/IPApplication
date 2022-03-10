using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseInternalDetailsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        public CaseInternalDetailsController(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/internal-details")]
        public dynamic GetCaseInternalDetails(int caseKey)
        {
            var dateCreatedEvent = _dbContext.Set<CaseEvent>().SingleOrDefault(v => v.CaseId == caseKey && v.EventNo == (int) KnownEvents.DateOfEntry);
            var dateLastChangedEvent = _dbContext.Set<CaseEvent>().SingleOrDefault(v => v.CaseId == caseKey && v.EventNo == (int) KnownEvents.DateOfLastChange);
            var canAccessLink = _taskSecurityProvider.HasAccessTo(ApplicationTask.LaunchScreenDesigner);   
            return new 
            {
                DateCreated = dateCreatedEvent?.EventDate,
                DateChanged = dateLastChangedEvent?.EventDate,
                CanAccessLink = canAccessLink
            };
        }
    }
}