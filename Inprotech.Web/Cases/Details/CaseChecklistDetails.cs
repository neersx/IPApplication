using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseChecklistDetails
    {
        Task<ChecklistTypeAndSelectedOne> GetChecklistTypes(int caseId);
        Task<IEnumerable<CaseChecklistQuestions>> GetChecklistData(int caseKey, int? checklistCriteriaKey);
        Task<IEnumerable<ChecklistDocuments>> GetChecklistDocuments(int caseKey, int checklistCriteriaKey);
    }

    public class CaseChecklistDetails : ICaseChecklistDetails
    {
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _now;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDisplayFormattedName _displayFormattedName;

        public CaseChecklistDetails(IDbContext dbContext,
                                  IPreferredCultureResolver preferredCultureResolver,
                                  ISecurityContext securityContext,
                                  Func<DateTime> now, IDisplayFormattedName displayFormattedName)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _securityContext = securityContext;
            _now = now;
            _displayFormattedName = displayFormattedName;
        }

        public async Task<ChecklistTypeAndSelectedOne> GetChecklistTypes(int caseId)
        {
            var validChecklist = await GetValidChecklistTypes(caseId);
            if (validChecklist == null) return null;
            var caseChecklistTypes = validChecklist as CaseChecklistTypes[] ?? validChecklist.ToArray();
            var defaultSelectedChecklist = caseChecklistTypes.FirstOrDefault();
            return new ChecklistTypeAndSelectedOne 
            {
                SelectedChecklistType = defaultSelectedChecklist?.ChecklistType ?? 0,
                SelectedChecklistCriteriaKey = defaultSelectedChecklist?.ChecklistCriteriaKey,
                ChecklistTypes = caseChecklistTypes.OrderBy(_ => _.ChecklistTypeDescription)
            };
        }

        public async Task<IEnumerable<CaseChecklistQuestions>> GetChecklistData(int caseKey, int? checklistCriteriaKey)
        {
            var culture = _preferredCultureResolver.Resolve();
            var periodTypeTableCode = _dbContext.Set<TableCode>()
                                                 .Where(_ => _.TableTypeId == (int)TableTypes.PeriodType);

            var allCaseEvents = _dbContext.Set<CaseEvent>().Where(_ => _.CaseId == caseKey);
            var maxCycleEvents = from v in allCaseEvents
                                           .GroupBy(_ => new {_.CaseId, _.EventNo})
                                           .Select(i => new {i.Key, Cycle = i.Max(_ => _.Cycle)})
                                 join g in allCaseEvents on new { v.Key.EventNo, v.Cycle, v.Key.CaseId } equals new { g.EventNo, g.Cycle, g.CaseId } into nd
                                 from ce in nd.DefaultIfEmpty()
                                 select new MaxCycleCaseEvents
                                 {
                                     CaseId = v.Key.CaseId, 
                                     EventNo = v.Key.EventNo, 
                                     Cycle = v.Cycle,
                                     CaseEvent = nd.FirstOrDefault()
                                 };

            var interim = from v in _dbContext.Set<ChecklistItem>()
                          join i in _dbContext.Set<Question>() on v.QuestionId equals i.Id
                          join x in _dbContext.Set<CaseChecklist>().Where(x1 => x1.CaseId == caseKey) on
                              new {CaseId = caseKey, v.QuestionId} equals
                              new {x.CaseId, QuestionId = x.QuestionNo} into que
                          from a in que.DefaultIfEmpty()
                          join n in maxCycleEvents on v.YesAnsweredEventId equals n.EventNo into h
                          from yes in h.DefaultIfEmpty()
                          join nn in maxCycleEvents on v.NoAnsweredEventId equals nn.EventNo into hh
                          from no in hh.DefaultIfEmpty()
                          where v.CriteriaId == checklistCriteriaKey
                          select new
                          {
                              YesNoOption = v.YesNoRequired ?? i.YesNoRequired,
                              CountOption = v.CountRequired ?? i.CountRequired,
                              AmountOption = v.AmountRequired ?? i.AmountRequired,
                              YesDateOption = v.YesAnsweredEventId == null ? 0 : 1,
                              NoDateOption = v.NoAnsweredEventId == null ? 0 : 1,
                              v.DateRequired,
                              StaffNameOption = v.EmployeeRequired ?? i.EmployeeRequired,
                              PeriodTypeOption = v.PeriodTypeRequired ?? i.PeriodTypeRequired,
                              TextOption = v.TextRequired ?? i.TextRequired,
                              QuestionNo = i.Id,
                              v.Question,
                              SequenceNo = v.SequenceNo ?? 0,
                              ListSelectionTypeId = i.TableType,
                              IsAnswered = a != null,
                              ListSelectionKey = a != null ? a.TableCode : null,
                              YesAnswer = a != null && a.YesNoAnswer == (decimal)1 || a == null && (v.YesNoRequired ?? i.YesNoRequired) == 4,
                              NoAnswer = a != null && a.YesNoAnswer == (decimal)0 || a == null && (v.YesNoRequired ?? i.YesNoRequired) == 5,
                              YesNoAnswer = a != null ? a.YesNoAnswer : null,
                              AmountValue = a != null ? a.ValueAnswer : null,
                              CountValue = a != null ? a.CountAnswer : null,
                              EnteredDeadline = a != null ? a.YesNoAnswer == 1m ? yes != null && yes.CaseEvent != null ? yes.CaseEvent.EnteredDeadline : null :
                                  a.YesNoAnswer == 0m ? no != null && no.CaseEvent != null ? no.CaseEvent.EnteredDeadline : null : null : null,
                              TextValue = a != null ? a.ChecklistText : null,
                              ProductCode = a != null ? a.ProductCode : null,
                              IsProcessed = a != null ? a.ProcessedFlag : null,
                              StaffNameKey = a != null ? a.EmployeeId : null,
                              PeriodTypeKey = a != null ? a.YesNoAnswer == 1m ? yes != null ? yes.CaseEvent != null ? yes.CaseEvent.PeriodType : null : null :
                                  a.YesNoAnswer == 0m ? no != null ? no.CaseEvent != null ? no.CaseEvent.PeriodType : null : null : null : null,
                              YesEventDate = yes != null ? yes.CaseEvent != null ? v.DueDateFlag == 1m ? yes.CaseEvent.EventDueDate : yes.CaseEvent.EventDate : null : null,
                              NoEventDate = no != null ? no.CaseEvent != null ? v.NoDueDateFlag == 1m ? no.CaseEvent.EventDueDate : no.CaseEvent.EventDate : null : null,
                              v.SourceQuestion,
                              v.AnswerSourceYes,
                              v.AnswerSourceNo,
                              v.YesAnsweredEventId,
                              v.DueDateFlag,
                              v.NoAnsweredEventId,
                              v.NoDueDateFlag,
                              v.YesRateNo,
                              v.NoRateNo,
                              Instructions = DbFuncs.GetTranslation(i.Instructions, null, i.InstructionsTid, culture)
                          };

            var results = (from a in interim
                           join ptc in periodTypeTableCode on a.PeriodTypeKey equals ptc.UserCode into ptcData
                           from ptcd in ptcData.DefaultIfEmpty()
                           join tt in _dbContext.Set<TableType>() on a.ListSelectionTypeId equals tt.Id into ttData
                           from ttd in ttData.DefaultIfEmpty()
                           join tc in _dbContext.Set<TableCode>() on a.ListSelectionKey equals tc.Id into tcData
                           from tcd in tcData.DefaultIfEmpty()
                           join q in _dbContext.Set<Question>() on a.SourceQuestion equals q.Id into qData
                           from qd in qData.DefaultIfEmpty()
                           join r in _dbContext.Set<Event>() on a.YesAnsweredEventId equals r.Id into yesEvent
                           from rr in yesEvent.DefaultIfEmpty()
                           join o in _dbContext.Set<Event>() on a.NoAnsweredEventId equals o.Id into noEvent
                           from oo in noEvent.DefaultIfEmpty()
                           join s in _dbContext.Set<Rates>() on a.YesRateNo equals s.Id into yesRate
                           from ss in yesRate.DefaultIfEmpty()
                           join e in _dbContext.Set<Rates>() on a.NoRateNo equals e.Id into noRate
                           from ee in noRate.DefaultIfEmpty()
                           orderby a.SequenceNo
                           select new CaseChecklistQuestions
                           {
                               YesNoOption = (int?)a.YesNoOption,
                               CountOption = (int?)a.CountOption,
                               AmountOption = (int?)a.AmountOption,
                               TextOption = (int?)a.TextOption,
                               YesDateOption = (int?)a.YesDateOption,
                               NoDateOption = (int?)a.NoDateOption,
                               StaffNameOption = (int?)a.StaffNameOption,
                               PeriodTypeOption = (int?)a.PeriodTypeOption,
                               QuestionNo = a.QuestionNo,
                               Question = a.Question,
                               PeriodTypeKey = a.PeriodTypeKey,
                               IsAnswered = a.IsAnswered,
                               IsAnswerRequired = (int?)a.YesNoOption == 1 || (int?)a.CountOption == 1 || (int?)a.AmountOption == 1 || (int?)a.TextOption == 1
                                                    || (int?)a.StaffNameOption == 1 || (int?)a.PeriodTypeOption == 1 || (int?)a.DateRequired == 1,
                               IsProcessed = a.IsProcessed,
                               YesAnswer = a.YesAnswer,
                               NoAnswer = a.NoAnswer,
                               YesNoAnswer = a.YesNoAnswer,
                               AmountValue = a.AmountValue,
                               CountValue = a.EnteredDeadline ?? a.CountValue,
                               TextValue = a.TextValue,
                               ProductCode = a.ProductCode,                              
                               StaffNameKey = a.StaffNameKey,
                               DateValue = a.YesAnswer || (!a.YesAnswer && !a.NoAnswer) ? a.YesEventDate : a.NoAnswer ? a.NoEventDate : null,
                               PeriodTypeDescription = ptcd != null ? DbFuncs.GetTranslation(ptcd.Name, null, ptcd.NameTId, culture) : null,
                               ListSelectionTypeId = a.ListSelectionTypeId,
                               ListSelectionKey = a.ListSelectionKey,
                               ListSelectionTypeDescription = ttd != null ? DbFuncs.GetTranslation(ttd.Name, null, ttd.NameTId, culture) : null,
                               ListSelection = tcd != null ? DbFuncs.GetTranslation(tcd.Name, null, tcd.NameTId, culture) : null,
                               SourceQuestion = qd != null ? DbFuncs.GetTranslation(qd.QuestionString, null, qd.QuestionTid, culture) : null,
                               SourceQuestionId = qd != null ? qd.Id : (int?) null,
                               AnswerSourceYes = (int?)a.AnswerSourceYes,
                               AnswerSourceNo = (int?)a.AnswerSourceNo,
                               YesEventDesc = rr != null ? DbFuncs.GetTranslation(rr.Description, null, rr.DescriptionTId, culture) : null,
                               YesEventNumber = rr != null ? rr.Id : (int?) null,
                               YesDueDateFlag = a.DueDateFlag.HasValue && a.DueDateFlag.Value == 1m,
                               NoEventDesc = oo != null ? DbFuncs.GetTranslation(oo.Description, null, oo.DescriptionTId, culture) : null,
                               NoEventNumber = oo != null ? oo.Id : (int?) null,
                               NoDueDateFlag = a.NoDueDateFlag.HasValue && a.NoDueDateFlag.Value == 1m,
                               YesRateDesc = ss != null ? DbFuncs.GetTranslation(ss.RateDescription, null, ss.RateDescTId, culture) : null,
                               YesRateNumber = ss != null ? ss.Id : (int?) null,
                               NoRateDesc = ee != null ? DbFuncs.GetTranslation(ee.RateDescription, null, ee.RateDescTId, culture) : null,
                               NoRateNumber = ee != null ? ee.Id : (int?) null,
                               Instructions = a.Instructions
                           }).ToArray();
            var nameIds = results.Where(_ => _.StaffNameKey != null).Select(_ => (int)_.StaffNameKey)
                                 .Distinct().ToArray();
            var formattedNames = await _displayFormattedName.For(nameIds);
            var checklistDocuments = (from p in _dbContext.Set<ChecklistLetter>().Where(_ => _.CriteriaId == checklistCriteriaKey)
                                      join d in _dbContext.Set<Document>() on p.LetterNo equals d.Id into docs
                                      join v in _dbContext.Set<ChecklistItem>() on p.QuestionId equals v.QuestionId into items
                                      from vv in items.DefaultIfEmpty()
                                      where p.QuestionId != null && vv.CriteriaId == checklistCriteriaKey
                                      select new
                                      {
                                          p.QuestionId,
                                          Documents = docs.Select(v => v.Name)
                                      }).ToList().Select(x => new
            {
                x.QuestionId, Documents = string.Join(", ", x.Documents)
            }).ToDictionary(k => k.QuestionId, v => v.Documents);

            foreach (var questions in results)
            {
                if (checklistDocuments.TryGetValue(questions.QuestionNo, out _))
                {
                    questions.Letters = checklistDocuments[questions.QuestionNo];
                }
                if (questions.ListSelectionTypeId != null)
                {
                    questions.ListSelectionType = GetSelectionTypes(culture,  questions.ListSelectionTypeId);
                }
                
                if (questions.StaffNameKey == null) continue;
                var nameId = questions.StaffNameKey ?? 0;
                questions.StaffName = formattedNames?[nameId]?.Name + " {" + formattedNames?[nameId]?.NameCode + "}";
                questions.StaffNameCode = formattedNames?[nameId]?.NameCode;
            }

            return results;
        }

        public async Task<IEnumerable<ChecklistDocuments>> GetChecklistDocuments(int caseKey, int checklistCriteriaKey)
        {
            var culture = _preferredCultureResolver.Resolve();
            var result = from p in _dbContext.Set<ChecklistLetter>().Where(_ => _.CriteriaId == checklistCriteriaKey)
                   join d in _dbContext.Set<Document>() on p.LetterNo equals d.Id
                   where p.QuestionId == null
                   select new ChecklistDocuments
                   {
                       DocumentId = p.LetterNo,
                       DocumentName = DbFuncs.GetTranslation(d.Name, null, d.NameTId, culture)
                   };
            return result;
        }

        List<SelectionType> GetSelectionTypes(string culture, short? tableType)
        {
            var selectionTypes = _dbContext.Set<TableCode>()
                                          .Select(_ => new SelectionType
                                          {
                                              Key = _.Id.ToString(),
                                              Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                              TableType = _.TableTypeId
                                          })
                                          .Where(_ => _.TableType == tableType)
                                          .ToList();

            return selectionTypes;
        }

        async Task<IEnumerable<CaseChecklistTypes>> GetValidChecklistTypes(int caseId)
        {
            var culture = _preferredCultureResolver.Resolve();
            
            var profileId = _securityContext.User.Profile?.Id;

            var @case = _dbContext.Set<Case>().Single(_ => _.Id == caseId);
            var now = _now();
            var defaultCountryCode = _dbContext.Set<ValidChecklist>()
                                                .Where(_ => _.PropertyTypeId == @case.PropertyTypeId 
                                                        && _.CaseTypeId == @case.TypeId
                                                        && (_.CountryId == @case.CountryId || _.CountryId == InprotechKaizen.Model.KnownValues.DefaultCountryCode))
                                                .Select(_ => _.CountryId).Min();

            var validChecklist = await (from vc in _dbContext.Set<ValidChecklist>()
                                                .Where(_ => _.PropertyTypeId == @case.PropertyTypeId 
                                                        && _.CaseTypeId == @case.TypeId
                                                        && _.CountryId == defaultCountryCode)
                                                select new CaseChecklistTypes 
                                                {
                                                    ChecklistType = vc.ChecklistType,
                                                    ChecklistTypeDescription = DbFuncs.GetTranslation(vc.ChecklistDescription, null, vc.ChecklistDescriptionTId, culture),
                                                    ChecklistCriteriaKey = DbFuncs.GetCriteriaNo(caseId, CriteriaPurposeCodes.CheckList, vc.ChecklistType.ToString(), now, profileId)
                                                }).ToArrayAsync();
            return validChecklist;
        }
    }

    public class CaseChecklistTypes
    {
        public int ChecklistType {get; set;}
        public string ChecklistTypeDescription {get; set;}
        public int? ChecklistCriteriaKey { get; set; }
    }

    public class MaxCycleCaseEvents
    {
        public int CaseId {get; set;}
        public int EventNo {get; set;}
        public short Cycle { get; set; }
        public CaseEvent CaseEvent { get; set; }
    }

    public class ChecklistTypeAndSelectedOne
    {
        public IEnumerable<CaseChecklistTypes> ChecklistTypes { get; set; }
        public int SelectedChecklistType { get; set; }
        public int? SelectedChecklistCriteriaKey { get; set; }
    }
    public class CaseChecklistQuestions
    {
        public int? YesNoOption { get; set; }
        public int? CountOption { get; set; }
        public int? AmountOption { get; set; }
        public int? YesDateOption { get; set; }
        public int? NoDateOption { get; set; }
        public int? StaffNameOption { get; set; }
        public int? PeriodTypeOption { get; set; }
        public int? TextOption { get; set; }
        public short QuestionNo { get; set; }
        public string Question { get; set; }
        public int SequenceNo { get; set; }
        public bool IsAnswered { get; set; }
        public bool IsAnswerRequired { get; set; }
        public short? ListSelectionTypeId { get; set; }
        public List<SelectionType> ListSelectionType { get; set; }
        public string ListSelectionTypeDescription { get; set; }
        public int? ListSelectionKey { get; set; }
        public string ListSelection { get; set; }
        public bool YesAnswer { get; set; }
        public bool NoAnswer { get; set; }
        public decimal? YesNoAnswer { get; set; }
        public decimal? AmountValue { get; set; }
        public DateTime? DateValue { get; set; }
        public int? CountValue { get; set; }
        public string TextValue { get; set; }
        public string PeriodTypeKey { get; set; }
        public string PeriodTypeDescription { get; set; }
        public int? StaffNameKey { get; set; }
        public string StaffNameCode { get; set; }
        public string StaffName { get; set; }
        public int? ProductCode { get; set; }
        public decimal? IsProcessed { get; set; }
        public string SourceQuestion { get; set; }
        public int? SourceQuestionId { get; set; }
        public int? AnswerSourceYes { get; set; }
        public int? AnswerSourceNo { get; set; }
        public string YesEventDesc { get; set; }
        public int? YesEventNumber { get; set; }
        public bool YesDueDateFlag { get; set; }
        public string NoEventDesc { get; set; }
        public int? NoEventNumber { get; set; }
        public bool NoDueDateFlag { get; set; }
        public string YesRateDesc { get; set; }
        public string NoRateDesc { get; set; }
        public string Letters { get; set; }
        public int? YesRateNumber { get; set; }
        public int? NoRateNumber { get; set; }
        public string Instructions { get; set; }
    }
    public class SelectionType
    {
        public string Key { get; set; }
        public string Value { get; set; }
        public short TableType { get; set; }
    }

    public class ChecklistDocuments
    {
        public string DocumentName {get; set;}
        public int DocumentId { get; set; }
        public bool RegenerateGeneralDoc { get; set; }
    }
}
