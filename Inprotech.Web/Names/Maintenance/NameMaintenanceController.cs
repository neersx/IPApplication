using System.Collections.Generic;
using System.Linq;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Names.Maintenance
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/name")]
    public class NameMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly INameMaintenanceSave _nameMaintenanceSave;
        readonly ITopicsUpdater<Name> _topicsUpdater;
        public NameMaintenanceController(IDbContext dbContext, INameMaintenanceSave nameMaintenanceSave, ITopicsUpdater<Name> topicsUpdater)
        {
            _dbContext = dbContext;
            _nameMaintenanceSave = nameMaintenanceSave;
            _topicsUpdater = topicsUpdater;
        }
        
        [HttpPost]
        [RequiresNameAuthorization(PropertyPath = "model.NameId")]
        [AppliesToComponent(KnownComponents.Name)]
        [RequiresAccessTo(ApplicationTask.MaintainName, ApplicationTaskAccessLevel.Modify)]
        [Route("nameview/maintenance")]
        public MaintenanceSaveResponse SaveData(NameMaintenanceSaveModel model)
        {
            var name = _dbContext.Set<Name>().Single(_ => _.Id == model.NameId);
            var errors = _topicsUpdater.Validate(model, TopicGroups.Names, name).ToList();
            if (errors.Any())
            {
                return new MaintenanceSaveResponse
                {
                    Status = "error",
                    Errors = errors
                };
            }
            var saved = false;
            IEnumerable<dynamic> sanityCheckResults = null;
            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var result = _nameMaintenanceSave.Save(model, name);
                var sanityCheckErrors = result.SanityCheckResults.Where(_ => !_.Details.IsWarning).ToList();
                if (!sanityCheckErrors.Any() || sanityCheckErrors.All(_=> _.Details.CanOverride) && model.IgnoreSanityCheck)
                {
                    tcs.Complete();
                    saved = true;
                }
                if (!model.IgnoreSanityCheck)
                {
                    sanityCheckResults = result.SanityCheckResults.Select(_ => _.Details);
                }
            }
            _topicsUpdater.PostSave(model, TopicGroups.Names, name);
            return new MaintenanceSaveResponse
            {
                SanityCheckResults = sanityCheckResults,
                SavedSuccessfully = saved
            };
        }
    }

    public class MaintenanceSaveResponse
    {
        public IEnumerable<ValidationError> Errors { get; set; }
        public IEnumerable<dynamic> SanityCheckResults { get; set; }
        public string Status { get; set; }
        public bool SavedSuccessfully { get; set; }
    }
}
