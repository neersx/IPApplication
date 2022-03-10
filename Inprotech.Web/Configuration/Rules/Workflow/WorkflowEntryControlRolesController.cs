using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRulesProtected)]
    public class WorkflowEntryControlRolesController : ApiController
    {
        readonly IDbContext _dbContext;
            
        public WorkflowEntryControlRolesController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("api/configuration/roles/{roleId:int}/users")]
        public dynamic GetUsersForRole(int roleId)
        {
            return _dbContext.Set<Role>()
                             .Single(r => r.Id == roleId)
                             .Users
                             .OrderBy(u => u.UserName)
                             .Select(u => new
                             {
                                 Username = u.UserName, 
                                 Name = FormattedName.For(u.Name.LastName, u.Name.FirstName)
                             });
        }
    }
}
