using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reports;

namespace Inprotech.Web.FinancialReports
{
    [Authorize]
    public class ReportController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IFileHelpers _fileHelpers;

        public ReportController(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider, IFileHelpers fileHelpers)
        {
            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
            _fileHelpers = fileHelpers;
        }

        [HttpGet]
        [Route("api/reports/report/{id}")]
        public HttpResponseMessage Get(int id)
        {
            var authorisedTasks = _taskSecurityProvider.ListAvailableTasks()
                                                       .Where(vt => vt.CanExecute)
                                                       .Select(vt => vt.TaskId);

            var report = _dbContext.Set<ExternalReport>()
                                   .FirstOrDefault(r => r.Id == id);

            if(report == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            if(!authorisedTasks.Contains(report.TaskId))
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            
            var filePath = @"Assets\Reports\Financial\" + report.Path;
            
            if (!_fileHelpers.Exists(filePath))
                throw Exceptions.NotFound("The requested report does not exist.");
            
            var result = new HttpResponseMessage(HttpStatusCode.OK)
                         {
                             Content = new StreamContent(_fileHelpers.OpenRead(filePath))
                         };

            result.Content.Headers.ContentType = new MediaTypeHeaderValue("application/vnd.ms-excel");
            result.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
                                                        {
                                                            FileName = report.Path
                                                        };

            return result;
        }
    }
}