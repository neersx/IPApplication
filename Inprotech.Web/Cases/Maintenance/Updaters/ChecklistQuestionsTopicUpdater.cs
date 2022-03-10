using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Accounting.Charge;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using InprotechKaizen.Model.Components.ChargeGeneration;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.DocumentGeneration.Classic;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json.Linq;
using BestChargeRates = InprotechKaizen.Model.Components.ChargeGeneration.BestChargeRates;
using Document = InprotechKaizen.Model.Documents.Document;

namespace Inprotech.Web.Cases.Maintenance.Updaters
{
    public class ChecklistQuestionsTopicUpdater : ITopicDataUpdater<Case>
    {
        readonly IEventUpdater _eventUpdater;
        readonly IDbContext _dbContext;
        readonly IDocumentGenerator _documentGenerator;
        readonly IChargeGenerator _chargeGenerator;
        readonly IRatesCommand _ratesCommand;
        readonly ITransactionRecordal _transactionRecordal;
        readonly ISiteConfiguration _siteConfiguration;
        readonly IComponentResolver _componentResolver;

        public ChecklistQuestionsTopicUpdater(IEventUpdater eventUpdater, IDbContext dbContext, IDocumentGenerator documentGenerator, IChargeGenerator chargeGenerator, IRatesCommand ratesCommand, ITransactionRecordal transactionRecordal, ISiteConfiguration siteConfiguration, IComponentResolver componentResolver)
        {
            _eventUpdater = eventUpdater;
            _dbContext = dbContext;
            _documentGenerator = documentGenerator;
            _chargeGenerator = chargeGenerator;
            _ratesCommand = ratesCommand;
            _transactionRecordal = transactionRecordal;
            _siteConfiguration = siteConfiguration;
            _componentResolver = componentResolver;
        }

        public void UpdateData(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            var topic = topicData.ToObject<ChecklistQuestionsSaveModel>();
            var caseChecklists = @case.CaseChecklists.ToList();
            var hasChecklistBeenProceedBefore = caseChecklists.Any(v => v.ProcessedFlag == 1m);
            var reasonNo = _siteConfiguration.TransactionReason ? _siteConfiguration.ReasonInternalChange : null;
            _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reasonNo, _componentResolver.Resolve(KnownComponents.Checklist));

            foreach (var e in topic.Rows)
            {
                var editedCaseChecklist = caseChecklists.SingleOrDefault(v => v.QuestionNo == e.QuestionId);
                if (editedCaseChecklist == null)
                {
                    editedCaseChecklist = new CaseChecklist(topic.ChecklistTypeId, @case.Id, e.QuestionId);
                    @case.CaseChecklists.Add(editedCaseChecklist);
                }
                editedCaseChecklist.CriteriaId = topic.ChecklistCriteriaKey;
                editedCaseChecklist.CheckListTypeId = topic.ChecklistTypeId;
                editedCaseChecklist.ChecklistText = e.TextValue;
                editedCaseChecklist.CountAnswer = e.CountValue;
                editedCaseChecklist.EmployeeId = e.StaffName?.Key;
                editedCaseChecklist.ValueAnswer = e.AmountValue;
                editedCaseChecklist.TableCode = e.ListSelection;
                editedCaseChecklist.ProcessedFlag = 1m;
                UpdateChecklistYesNoQuestionAndEvents(e, @case, editedCaseChecklist, topic);
                ProcessCharges(e, @case, topic, hasChecklistBeenProceedBefore);
            }
            ProcessMandatoryDocuments(topic, @case, hasChecklistBeenProceedBefore);
        }
        
        void UpdateChecklistYesNoQuestionAndEvents(ChecklistQuestionData e, Case @case, CaseChecklist editedCaseChecklist, ChecklistQuestionsSaveModel topic)
        {
            if (e.YesAnswer)
            {
                if (editedCaseChecklist.YesNoAnswer != 1m || e.RegenerateDocuments)
                    ProcessDocument(topic, @case, e.QuestionId, KnownRequiredAnswer.Yes);
                editedCaseChecklist.YesNoAnswer = 1m;
                if (e.YesUpdateEventId == null) return;
                var events = @case.CaseEvents.Where(q => q.EventNo == e.YesUpdateEventId);
                if (events.Any())
                {
                    var maxCycle = @case.CaseEvents.Where(q => q.EventNo == e.YesUpdateEventId).Max(c => c.Cycle);
                    if (e.DateValue != null)
                    {
                        if (e.YesDueDateFlag)
                            _eventUpdater.AddOrUpdateDueDateEvent(@case, (int) e.YesUpdateEventId, e.DateValue.Value.Date, maxCycle);
                        else
                            _eventUpdater.AddOrUpdateEvent(@case, (int) e.YesUpdateEventId, e.DateValue.Value.Date, maxCycle);
                    }
                    else
                    {
                        _eventUpdater.RemoveCaseEventDate(@case.CaseEvents.Single(l => l.EventNo == e.YesUpdateEventId && l.Cycle == maxCycle), e.YesDueDateFlag);
                    }
                    UpdateEventDeadline(e, @case.CaseEvents.SingleOrDefault(l => l.EventNo == e.YesUpdateEventId && l.Cycle == maxCycle), editedCaseChecklist);
                }
                else
                {
                    if (e.DateValue != null)
                    {
                        if (e.YesDueDateFlag)
                            _eventUpdater.AddOrUpdateDueDateEvent(@case, (int) e.YesUpdateEventId, e.DateValue.Value.Date, 1);
                        else
                            _eventUpdater.AddOrUpdateEvent(@case, (int) e.YesUpdateEventId, e.DateValue.Value.Date, 1);
                    }
                    UpdateEventDeadline(e, @case.CaseEvents.SingleOrDefault(l => l.EventNo == e.YesUpdateEventId && l.Cycle == 1), editedCaseChecklist);
                }
                return;
            }
            if (e.NoAnswer)
            {
                if (editedCaseChecklist.YesNoAnswer != 0m || e.RegenerateDocuments)
                    ProcessDocument(topic, @case, e.QuestionId, KnownRequiredAnswer.No);
                editedCaseChecklist.YesNoAnswer = 0m;
                if (e.NoUpdateEventId == null) return;
                var events = @case.CaseEvents.Where(q => q.EventNo == e.NoUpdateEventId);
                if (events.Any())
                {
                    var maxCycle = @case.CaseEvents.Where(q => q.EventNo == e.NoUpdateEventId).Max(w => w.Cycle);
                    if (e.DateValue != null)
                    {
                        if (e.NoDueDateFlag)
                            _eventUpdater.AddOrUpdateDueDateEvent(@case, (int) e.NoUpdateEventId, e.DateValue.Value.Date, maxCycle);
                        else
                            _eventUpdater.AddOrUpdateEvent(@case, (int) e.NoUpdateEventId, e.DateValue.Value.Date, maxCycle);
                    }
                    else
                    {
                        _eventUpdater.RemoveCaseEventDate(@case.CaseEvents.Single(l => l.EventNo == e.NoUpdateEventId && l.Cycle == maxCycle), e.NoDueDateFlag);
                    }
                    UpdateEventDeadline(e, @case.CaseEvents.SingleOrDefault(l => l.EventNo == e.NoUpdateEventId && l.Cycle == maxCycle), editedCaseChecklist);
                }
                else
                {
                    if (e.DateValue != null)
                    {
                        if (e.NoDueDateFlag)
                            _eventUpdater.AddOrUpdateDueDateEvent(@case, (int) e.NoUpdateEventId, e.DateValue.Value.Date, 1);
                        else
                            _eventUpdater.AddOrUpdateEvent(@case, (int) e.NoUpdateEventId, e.DateValue.Value.Date, 1);
                    }
                    UpdateEventDeadline(e, @case.CaseEvents.SingleOrDefault(l => l.EventNo == e.NoUpdateEventId && l.Cycle == 1), editedCaseChecklist);
                }
                return;
            }

            if (!e.NoAnswer && !e.YesAnswer && e.YesUpdateEventId != null)
            {
                var events = @case.CaseEvents.Where(q => q.EventNo == e.YesUpdateEventId);
                if (events.Any())
                {
                    var maxCycle = @case.CaseEvents.Where(q => q.EventNo == e.YesUpdateEventId).Max(c => c.Cycle);
                    if (e.DateValue != null)
                    {
                        if (e.YesDueDateFlag)
                            _eventUpdater.AddOrUpdateDueDateEvent(@case, (int) e.YesUpdateEventId, e.DateValue.Value.Date, maxCycle);
                        else
                            _eventUpdater.AddOrUpdateEvent(@case, (int) e.YesUpdateEventId, e.DateValue.Value.Date, maxCycle);
                        UpdateEventDeadline(e, @case.CaseEvents.SingleOrDefault(l => l.EventNo == e.YesUpdateEventId && l.Cycle == maxCycle), editedCaseChecklist);
                    }
                    else
                    {
                        _eventUpdater.RemoveCaseEventDate(@case.CaseEvents.Single(l => l.EventNo == e.YesUpdateEventId && l.Cycle == maxCycle), e.YesDueDateFlag);
                    }
                }
                else
                {
                    if (e.DateValue != null)
                    {
                        if (e.YesDueDateFlag)
                            _eventUpdater.AddOrUpdateDueDateEvent(@case, (int) e.YesUpdateEventId, e.DateValue.Value.Date, 1);
                        else
                            _eventUpdater.AddOrUpdateEvent(@case, (int) e.YesUpdateEventId, e.DateValue.Value.Date, 1);
                        UpdateEventDeadline(e, @case.CaseEvents.SingleOrDefault(l => l.EventNo == e.YesUpdateEventId && l.Cycle == 1), editedCaseChecklist);
                    }
                }
            }
            editedCaseChecklist.YesNoAnswer = null;
        }

        static void UpdateEventDeadline(ChecklistQuestionData e, CaseEvent caseEvent, CaseChecklist editedCaseChecklist)
        {
            if (e.PeriodTypeKey == null || caseEvent == null) return;
            caseEvent.EnteredDeadline = e.CountValue;
            editedCaseChecklist.CountAnswer = null;
        }

        public void ProcessMandatoryDocuments(ChecklistQuestionsSaveModel topic, Case @case, bool hasChecklistBeenProceedBefore)
        {
            if (hasChecklistBeenProceedBefore)
            {
                var regeneratingDocs = new int[] { };
                if (topic.GeneralDocs != null)
                {
                    regeneratingDocs = topic.GeneralDocs.Where(d => d.RegenerateGeneralDoc).Select(x => x.DocumentId).ToArray();
                }

                var documentsToQueue = from i in _dbContext.Set<Document>()
                                   where regeneratingDocs.Contains(i.Id)
                                   select i;

                foreach (var doc in documentsToQueue.ToList())
                {
                    _documentGenerator.QueueChecklistQuestionDocument(@case, topic.ChecklistTypeId, topic.ChecklistCriteriaKey, null, doc);
                }
            }
            else
            {
                var mandatoryDocuments = from v in _dbContext.Set<ChecklistLetter>().Where(v => v.CriteriaId == topic.ChecklistCriteriaKey)
                                       join i in _dbContext.Set<Document>() on v.LetterNo equals i.Id
                                       where v.QuestionId == null
                                       select i;
                foreach (var doc in mandatoryDocuments.ToList())
                {
                    _documentGenerator.QueueChecklistQuestionDocument(@case, topic.ChecklistTypeId, topic.ChecklistCriteriaKey, null, doc);
                }
            }
        }

        public void ProcessDocument(ChecklistQuestionsSaveModel topic, Case @case, short questionId, KnownRequiredAnswer requiredAnswer)
        {
            var docs = (from v in _dbContext.Set<ChecklistLetter>().Where(v => v.CriteriaId == topic.ChecklistCriteriaKey)
                        join i in _dbContext.Set<Document>() on v.LetterNo equals i.Id
                        where v.QuestionId == questionId && (v.RequiredAnswer == (decimal?) requiredAnswer || v.RequiredAnswer == (decimal?) KnownRequiredAnswer.YesOrNo)
                        select new {Document = i, v.QuestionId}).ToList();

            foreach (var doc in docs)
            {
                _documentGenerator.QueueChecklistQuestionDocument(@case, topic.ChecklistTypeId, topic.ChecklistCriteriaKey, doc.QuestionId, doc.Document);
            }
        }

        public void ProcessCharges(ChecklistQuestionData e, Case @case, ChecklistQuestionsSaveModel topic, bool hasChecklistBeenProceedBefore)
        {
            var bestRates = new List<BestChargeRates>();
            if (e.YesRateId != null && e.YesAnswer)
            {
                if (hasChecklistBeenProceedBefore && e.RegenerateCharges)
                    bestRates.AddRange(_ratesCommand.GetRates(@case.Id, e.YesRateId));
                if (!hasChecklistBeenProceedBefore)
                    bestRates.AddRange(_ratesCommand.GetRates(@case.Id, e.YesRateId));
            }

            if (e.NoRateId != null && e.NoAnswer)
            {
                if (hasChecklistBeenProceedBefore && e.RegenerateCharges)
                    bestRates.AddRange(_ratesCommand.GetRates(@case.Id, e.NoRateId));
                if (!hasChecklistBeenProceedBefore)
                    bestRates.AddRange(_ratesCommand.GetRates(@case.Id, e.NoRateId));
            }

            if (bestRates.Count == 0) return;
            foreach (var rate in bestRates)
            {
                _chargeGenerator.QueueChecklistQuestionCharge(@case, topic.ChecklistTypeId, topic.ChecklistCriteriaKey, e.QuestionId, rate, e);
            }
        }

        public void PostSaveData(JObject topicData, MaintenanceSaveModel model, Case parentRecord)
        {
        }
    }
}
