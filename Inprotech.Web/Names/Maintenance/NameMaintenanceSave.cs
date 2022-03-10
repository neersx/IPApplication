using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.DataValidation;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Names.Maintenance
{
    public interface INameMaintenanceSave
    {
        NameMaintenanceSaveResult Save(MaintenanceSaveModel model, Name name);
    }
    public class NameMaintenanceSave : INameMaintenanceSave
    {
        readonly IDbContext _dbContext;
        readonly ITransactionRecordal _transactionRecordal;
        readonly ITopicsUpdater<Name> _topicsUpdater;
        readonly IExternalDataValidator _externalDataValidator;

        public NameMaintenanceSave(IDbContext dbContext, ITransactionRecordal transactionRecordal, ITopicsUpdater<Name> topicsUpdater, IExternalDataValidator externalDataValidator)
        {
            _dbContext = dbContext;
            _transactionRecordal = transactionRecordal;
            _topicsUpdater = topicsUpdater;
            _externalDataValidator = externalDataValidator;
        }

        public NameMaintenanceSaveResult Save(MaintenanceSaveModel model, Name name)
        {
            var transactionNo = _transactionRecordal.RecordTransactionFor(name, NameTransactionMessageIdentifier.AmendedName);
            _topicsUpdater.Update(model, TopicGroups.Names, name);
            _dbContext.SaveChanges();

            var sanityCheckResults = _externalDataValidator.Validate(null, name.Id, transactionNo).ToList();

            return new NameMaintenanceSaveResult
            {
                SanityCheckResults = sanityCheckResults
            };
        }
    }

    public class NameMaintenanceSaveResult
    {
        public IEnumerable<ValidationResult> SanityCheckResults { get; set; }
        public NameMaintenanceSaveResult()
        {
            SanityCheckResults = new List<ValidationResult>();
        }
    }
}
