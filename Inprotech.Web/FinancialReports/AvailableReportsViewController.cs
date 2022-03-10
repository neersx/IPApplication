using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.FinancialReports.Models;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reports;

namespace Inprotech.Web.FinancialReports
{
    [Authorize]
    [ViewInitialiser]
    public class AvailableReportsViewController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        
        public AvailableReportsViewController(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
            _preferredCultureResolver = preferredCultureResolver;

        }

        [HttpGet]
        [Route("api/reports/availablereportsview")]
        public dynamic Get()
        {
            var culture = _preferredCultureResolver.Resolve();
            var authorisedTasks = _taskSecurityProvider.ListAvailableTasks()
                                                       .Where(vt => vt.CanExecute)
                                                       .Select(vt => vt.TaskId);

            var externalReports = _dbContext.Set<ExternalReport>()
                                            .Include(r => r.SecurityTask.ProvidedByFeatures.Select(f => f.Category))
                                            .Where(r => authorisedTasks.Contains(r.SecurityTask.Id));

            var translatedCategories = _dbContext.Set<TableCode>().Where(_ => _.TableTypeId == 98)
                                                 .Select(_ => new TranslatedCategory
                                                 {
                                                     Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                                     Id = _.Id
                                                 }).ToList();

            if (!externalReports.Any())            
                throw new HttpResponseException(HttpStatusCode.Forbidden);            

            return new AvailableReportsModel(externalReports, translatedCategories).CategorisedReports;
            
        }
    }

    public class TranslatedCategory
    {
        public string Name { get; set; }
        public int Id { get; set; }
    }
}
