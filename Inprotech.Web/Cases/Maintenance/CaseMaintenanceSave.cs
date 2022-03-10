using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.DataValidation;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Cases.Maintenance
{
    public interface ICaseMaintenanceSave
    {
        CaseMaintenanceSaveResult Save(Case @case, bool? modelIsPoliceImmediately, int? batchNo, CaseMaintenanceSaveModel model);
    }

    public class CaseMaintenanceSaveResult
    {
        public bool AnyPolicingRequests { get; set; }
        public IEnumerable<ValidationResult> SanityCheckResults { get; set; }

        public CaseMaintenanceSaveResult()
        {
            SanityCheckResults = new List<ValidationResult>();
        }
    }

    public class CaseMaintenanceSave : ICaseMaintenanceSave
    {
        readonly IDbContext _dbContext;
        readonly IChangeTracker _changeTracker;
        readonly IPolicingEngine _policingEngine;
        readonly ISiteConfiguration _siteConfiguration;
        readonly ITransactionRecordal _transactionRecordal;
        readonly IComponentResolver _componentResolver;
        readonly ITopicsUpdater<Case> _topicsUpdater;
        readonly IExternalDataValidator _externalDataValidator;
        public CaseMaintenanceSave(IDbContext dbContext,
                                   IChangeTracker changeTracker,
                                   IPolicingEngine policingEngine,
                                   ISiteConfiguration siteConfiguration,
                                   ITransactionRecordal transactionRecordal,
                                   IComponentResolver componentResolver,
                                   ITopicsUpdater<Case> topicsUpdater, IExternalDataValidator externalDataValidator)
        {
            _dbContext = dbContext;
            _changeTracker = changeTracker;
            _policingEngine = policingEngine;
            _siteConfiguration = siteConfiguration;
            _transactionRecordal = transactionRecordal;
            _componentResolver = componentResolver;
            _topicsUpdater = topicsUpdater;
            _externalDataValidator = externalDataValidator;
        }

        public CaseMaintenanceSaveResult Save(Case @case, bool? modelIsPoliceImmediately, int? batchNo, CaseMaintenanceSaveModel model)
        {
            var reasonNo = _siteConfiguration.TransactionReason
                ? _siteConfiguration.ReasonInternalChange
                : null;
            var transactionNo = _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reasonNo, _componentResolver.Resolve(KnownComponents.Case));

            _topicsUpdater.Update(model, TopicGroups.Cases, @case);
            var anyPolicingRequests = QueuePolicingRequests(@case, batchNo);
            _topicsUpdater.PostSave(model, TopicGroups.Cases, @case);
            _dbContext.SaveChanges();

            var sanityCheckResults = _externalDataValidator.Validate(@case.Id, null, transactionNo).ToList();
            return new CaseMaintenanceSaveResult()
            {
                AnyPolicingRequests = anyPolicingRequests,
                SanityCheckResults = sanityCheckResults
            };
        }

        bool QueuePolicingRequests(Case @case, int? batchNo)
        {
            var anyPolicingRequests = false;

            foreach (var ev in @case.CaseEvents.Where(_changeTracker.HasChanged))
            {
                _policingEngine.PoliceEvent(ev, ev.CreatedByCriteriaKey, batchNo, ev.CreatedByActionKey);
                anyPolicingRequests = true;
            }

            return anyPolicingRequests;
        }
    }
}
