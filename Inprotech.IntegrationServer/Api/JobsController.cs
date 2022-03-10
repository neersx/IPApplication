using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using Dependable;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.Api
{
    [RequiresApiKey(ExternalApplicationName.InprotechServer, IsOneTimeUse = true)]
    public class JobsController : ApiController
    {
        readonly Dictionary<string, Func<JObject, SingleActivity>> _jobs = new (StringComparer.OrdinalIgnoreCase);

        public JobsController(IEnumerable<IPerformImmediateBackgroundJob> jobs)
        {
            foreach (var j in jobs)
            {
                _jobs[j.Type] = id => j.GetJob(id);
            }
        }

        [HttpPost]
        [Route("api/jobs/{type}/start")]
        public HttpResponseMessage Start(string type, JObject data)
        {
            var jobWorkflowBuilder = _jobs[type];

            var jobWorkflow = jobWorkflowBuilder(data);
            
            IntegrationServer.Configuration.Scheduler.Schedule(jobWorkflow);

            return new HttpResponseMessage(HttpStatusCode.OK);
        }
    }
}