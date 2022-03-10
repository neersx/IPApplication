using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Dynamic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Attachment;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.ContactActivities;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using ActivityAttachment = InprotechKaizen.Model.ContactActivities.ActivityAttachment;

namespace Inprotech.Web.Cases.Details
{
    public class CaseActivityAttachmentMaintenance : ActivityAttachmentMaintenanceBase
    {
        readonly IDbContext _dbContext;
        readonly IAttachmentMaintenance _attachmentMaintenance;
        readonly IActivityMaintenance _activityMaintenance;
        readonly IActions _actions;
        readonly IPreferredCultureResolver _culture;

        public CaseActivityAttachmentMaintenance(AttachmentFor attachmentFor, IDbContext dbContext, IAttachmentMaintenance attachmentMaintenance, IActivityMaintenance activityMaintenance, IActions actions, IPreferredCultureResolver culture, IAttachmentContentLoader attachmentContentLoader, ITransactionRecordal transactionRecordal) : base(attachmentFor, attachmentMaintenance, activityMaintenance, dbContext, attachmentContentLoader, transactionRecordal)

        {
            _dbContext = dbContext;
            _attachmentMaintenance = attachmentMaintenance;
            _activityMaintenance = activityMaintenance;
            _actions = actions;
            _culture = culture;
        }

        public override async Task<ExpandoObject> ViewDetails(int? caseId, int? eventId = null, string actionKey = null)
        {
            dynamic result = await _activityMaintenance.ViewDetails();

            if (caseId != null)
            {
                result.caseId = caseId;
                var caseDetails = await _dbContext.Set<Case>().Where(_ => _.Id == caseId.Value)
                                                  .Select(_ =>
                                                              new
                                                              {
                                                                  _.Irn,
                                                                  _.CountryId,
                                                                  _.PropertyTypeId,
                                                                  _.TypeId
                                                              }).SingleOrDefaultAsync();

                if (caseDetails == null)
                    return result;

                result.irn = caseDetails.Irn;

                if (eventId.HasValue)
                {
                    result.Event = GetEventDetails(eventId.Value, caseId.Value);
                }

                if (!string.IsNullOrEmpty(actionKey))
                {
                    result.actionName = await _actions.CaseViewActions(caseId.Value, caseDetails.CountryId, caseDetails.PropertyTypeId, caseDetails.TypeId)
                                                      .Where(_ => _.Code == actionKey)
                                                      .Select(_ => _.Name)
                                                      .FirstOrDefaultAsync();
                }
            }

            return result;
        }

        dynamic GetEventDetails(int eventId, int caseId)
        {
            var caseEvents = _dbContext.Set<CaseEvent>().Where(_ => _.CaseId == caseId && _.EventNo == eventId)
                                       .OrderByDescending(_=>_.Cycle)
                                       .Take(1);

            var culture = _culture.Resolve();

            var eventDetails = (from e in _dbContext.Set<Event>()
                                join oa in _dbContext.Set<OpenAction>() on caseId equals oa.CaseId
                                join ce in caseEvents on new {oa.CaseId} equals new {ce.CaseId}
                                join ec in _dbContext.Set<ValidEvent>() on oa.CriteriaId equals ec.CriteriaId
                                where e.Id == eventId && ec.EventId == e.Id
                                select new
                                {
                                    e.Id,
                                    Description = DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, culture) ?? DbFuncs.GetTranslation(e.Description, null, e.DescriptionTId, culture),
                                    IsCyclic = ec.NumberOfCyclesAllowed > 1,
                                    IsCaseEvent = true,
                                    CurrentCycle = ce.Cycle
                                }).FirstOrDefault();

            if (eventDetails != null)
                return eventDetails;

            return _dbContext.Set<Event>().Where(_ => _.Id == eventId)
                             .Select(_ => new
                             {
                                 _.Id,
                                 Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture),
                                 IsCyclic = false,
                                 IsCaseEvent = false
                             }).SingleOrDefault();
        }

        public override async Task<ActivityAttachmentModel> GetAttachment(int activityKey, int sequenceNo)
        {
            var details = await base.GetAttachment(activityKey, sequenceNo);

            if (details.EventId.HasValue && details.ActivityCaseId.HasValue)
            {
                var eventDetails = GetEventDetails(details.EventId.Value, details.ActivityCaseId.Value);
                details.EventDescription = eventDetails?.Description;
                details.EventIsCyclic = eventDetails?.IsCyclic;
                details.IsCaseEvent = eventDetails?.IsCaseEvent;
                details.CurrentCycle = eventDetails?.CurrentCycle;
            }

            return details;
        }

        async Task<( bool isCycleValidOrNotApplicable, int lastCycle)> IsEventCycleValid(ActivityAttachmentModel activityAttachmentData)
        {
            if (!activityAttachmentData.EventId.HasValue || !activityAttachmentData.ActivityCaseId.HasValue)
            {
                return (true, 0);
            }

            activityAttachmentData.EventCycle ??= 1;

            var lastCycleOfEvent = await _dbContext.Set<CaseEvent>().Where(_ => _.CaseId == activityAttachmentData.ActivityCaseId.Value && _.EventNo == activityAttachmentData.EventId.Value)
                                                   .MaxAsync(_ => _.Cycle);

            return activityAttachmentData.EventCycle.Value > lastCycleOfEvent ? (false, lastCycleOfEvent) : (true, lastCycleOfEvent);
        }

        public override async Task<ActivityAttachmentModel> InsertAttachment(ActivityAttachmentModel activityAttachmentData)
        {
            var (isCycleValidOrNotApplicable, lastCycle) = await IsEventCycleValid(activityAttachmentData);
            if (!isCycleValidOrNotApplicable)
            {
                throw new Exception($"Provided cycle for the caseEvent is invalid. Max cycle for event possible is {lastCycle}");
            }

            return await base.InsertAttachment(activityAttachmentData);
        }

        public override async Task<ActivityAttachmentModel> UpdateAttachment(ActivityAttachmentModel activityActivityAttachment)
        {
            var (isCycleValidOrNotApplicable, lastCycle) = await IsEventCycleValid(activityActivityAttachment);
            if (!isCycleValidOrNotApplicable)
            {
                throw new Exception($"Provided cycle for the caseEvent is invalid. Max cycle for event possible is {lastCycle}");
            }

            return await base.UpdateAttachment(activityActivityAttachment);
        }

        public override async Task<bool> DeleteAttachment(ActivityAttachmentModel activityAttachmentData)
        {
            if (activityAttachmentData == null) throw new ArgumentNullException(nameof(activityAttachmentData));
            if (activityAttachmentData.ActivityId == null) throw new ArgumentNullException(nameof(activityAttachmentData.ActivityId));

            return await base.DeleteAttachment(activityAttachmentData, true);
        }

        public override async Task<IEnumerable<ActivityAttachmentModel>> GetAttachments(int caseId, CommonQueryParameters param)
        {
            var attachments = await _dbContext.Set<ActivityAttachment>().Include(_ => _.Activity)
                                              .Where(_ => _.Activity.CaseId == caseId)
                                              .OrderBy(_ => _.ActivityId)
                                              .ThenBy(_ => _.SequenceNo)
                                              .AsPagedResultsAsync(param);

            if (attachments?.Data == null) throw new InvalidDataException(nameof(attachments));

            return attachments.Data.Select(_ => _attachmentMaintenance.ToAttachment(_, true));
        }
    }
}