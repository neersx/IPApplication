using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.IntegrationServer.Scheduling;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.IntegrationServer.Api
{
    [RequiresApiKey(ExternalApplicationName.InprotechServer, IsOneTimeUse = true)]
    public class ScheduleExecutionController : ApiController
    {
        readonly IScheduleRunner _scheduleRunner;
        readonly IDbContext _dbContext;

        public ScheduleExecutionController(IScheduleRunner scheduleRunner, IDbContext dbContext)
        {
            _scheduleRunner = scheduleRunner;
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("api/schedules/stop/{scheduleId}/{userId}")]
        public void Stop(int scheduleId, int userId)
        {
            var userFormattedName = _dbContext.Set<User>()
                                     .Single(_ => _.Id == userId)
                                     .Name.Formatted();

            _scheduleRunner.StopScheduleExecutions(scheduleId, userId, userFormattedName);
        }
    }
}