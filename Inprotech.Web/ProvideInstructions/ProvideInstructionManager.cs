using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Serialization;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Serialization;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search;
using Inprotech.Web.Search.TaskPlanner;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.Reminders;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.ProvideInstructions
{
    public interface IProvideInstructionManager
    {
        Task<dynamic> GetInstructions(string taskPlannerRowKey);
        Task<bool> Instruct(InstructionsRequest request);
    }

    public class ProvideInstructionManager : IProvideInstructionManager
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IReminderManager _reminderManager;
        readonly ISearchService _searchService;
        readonly ISecurityContext _securityContext;
        readonly ISerializeXml _serializeXml;
        readonly ITaskPlannerDetailsResolver _taskPlannerDetailsResolver;
        readonly IEventNotesResolver _eventNotesResolver;

        public ProvideInstructionManager(
            IDbContext dbContext,
            IPreferredCultureResolver preferredCultureResolver,
            IReminderManager reminderManager,
            ISearchService searchService,
            ISecurityContext securityContext,
            ISerializeXml serializeXml,
            ITaskPlannerDetailsResolver taskPlannerDetailsResolver,
            IEventNotesResolver eventNotesResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _reminderManager = reminderManager;
            _searchService = searchService;
            _securityContext = securityContext;
            _serializeXml = serializeXml;
            _taskPlannerDetailsResolver = taskPlannerDetailsResolver;
            _eventNotesResolver = eventNotesResolver;
        }

        public async Task<dynamic> GetInstructions(string taskPlannerRowKey)
        {
            if (string.IsNullOrWhiteSpace(taskPlannerRowKey)) throw new ArgumentNullException(nameof(taskPlannerRowKey));

            var details = await _taskPlannerDetailsResolver.Resolve(taskPlannerRowKey);
            if (details == null) throw new ArgumentException(nameof(taskPlannerRowKey));

            var searchRequest = new SearchRequestParams<ProvideInstructionsRequestFilter>
            {
                QueryContext = QueryContext.CaseInstructionSearchInternal,
                Criteria = new ProvideInstructionsRequestFilter
                {
                    ColumnFilterCriteria = new ColumnFilterCriteria
                    {
                        ProvideInstructions = new ProvideInstructions
                        {
                            AvailabilityFlags = new AvailabilityFlags
                            {
                                IsDueEvent = true
                            },
                            DueEvent = new DueEvent
                            {
                                CaseKey = details.CaseKey,
                                Cycle = details.Cycle ?? 1,
                                EventKey = details.EventNo
                            }
                        }
                    }
                }
            };

            var instructions = new List<CaseInstruction>();

            var searchResult = await _searchService.RunSearch(searchRequest);
            foreach (var r in searchResult.Rows)
            {
                instructions.Add(new CaseInstruction
                {
                    CaseKey = details.CaseKey,
                    InstructionCycle = (int)r["InstructionCycle"],
                    InstructionDefinitionKey = (int)r["InstructionDefinitionKey"],
                    InstructionName = r.ContainsKey("instructiondefinition") ? (string)JObject.FromObject(r["instructiondefinition"])["value"] : string.Empty,
                    InstructionExplanation = r.ContainsKey("InstructionExplanationAny") ? (string)r["InstructionExplanationAny"] : string.Empty,
                    Actions = await GetInstructionResponses(details.CaseKey, (int)r[$"InstructionCycle"], (int)r["InstructionDefinitionKey"]),
                    ResponseNo = string.Empty
                });
            }

            return new
            {
                details.Irn,
                EventText = details.EventDescription,
                EventDueDate = details.DueDate,
                Instructions = instructions
            };
        }

        public async Task<bool> Instruct(InstructionsRequest request)
        {
            if (request?.ProvideInstruction == null) throw new ArgumentNullException(nameof(request));
            if (request.ProvideInstruction.Instructions == null || !request.ProvideInstruction.Instructions.Any() || string.IsNullOrWhiteSpace(request.TaskPlannerRowKey))
                throw new ArgumentNullException();

            using (var sqlCommand = _dbContext.CreateStoredProcedureCommand(StoredProcedures.ProcessInstructions))
            {

                sqlCommand.Parameters.Add(new SqlParameter("@pnUserIdentityId", _securityContext.User.Id));
                sqlCommand.Parameters.Add(new SqlParameter("@psCulture", _preferredCultureResolver.Resolve()));
                sqlCommand.Parameters.Add(new SqlParameter("@ptXMLInstructions", _serializeXml.Serialize(request.ProvideInstruction)));
                await sqlCommand.ExecuteNonQueryAsync();

                var eventNoteList = new List<CaseEventNotes>();
                foreach (var inst in request.ProvideInstruction.Instructions)
                {
                    var caseEventId = _dbContext.Set<CaseEvent>().SingleOrDefault(_ => _.CaseId == inst.CaseKey
                                                                                       && _.Cycle == inst.InstructionCycle
                                                                                       && _.EventNo == inst.SelectedAction.EventNo);
                    if (caseEventId == null || !inst.SelectedAction.EventNotes.Any()) continue;

                    foreach (var note in inst.SelectedAction.EventNotes)
                    {
                        eventNoteList.Add(new CaseEventNotes
                        {
                            CaseEventId = caseEventId.Id,
                            EventNoteType = note.NoteType,
                            EventText = note.EventText
                        });
                    }
                }

                await _eventNotesResolver.Update(eventNoteList);
                await _reminderManager.MarkAsReadOrUnread(new ReminderReadUnReadRequest { TaskPlannerRowKeys = new[] { request.TaskPlannerRowKey }, IsRead = true });
            }

            return true;
        }

        async Task<List<CaseInstructionResponse>> GetInstructionResponses(int caseKey, int instructionCycle, int instructionDefinitionKey)
        {
            var result = new List<CaseInstructionResponse>
            {
                new()
                {
                    ResponseLabel = "taskPlanner.provideInstructions.noAction",
                    ResponseSequence = string.Empty
                }
            };

            var culture = _preferredCultureResolver.Resolve();
            var instructionResponse = await (from r in _dbContext.Set<InstructionResponse>()
                                             join c in _dbContext.Set<Case>() on caseKey equals c.Id into c1
                                             from c in c1.DefaultIfEmpty()
                                             join ea in _dbContext.Set<Event>() on r.DisplayEventNo equals ea.Id into ea1
                                             from ea in ea1.DefaultIfEmpty()
                                             join cea in _dbContext.Set<CaseEvent>()
                                                 on new { CaseId = c.Id, EventNo = ea.Id, Cycle = ea.NumberOfCyclesAllowed == 1 ? 1 : instructionCycle, IsOccurredFlag = true }
                                                 equals new { cea.CaseId, cea.EventNo, Cycle = (int)cea.Cycle, IsOccurredFlag = cea.IsOccurredFlag > 0 }
                                                 into cea1
                                             from cea in cea1.DefaultIfEmpty()
                                             join eh in _dbContext.Set<Event>()
                                                 on r.HideEventNo equals eh.Id into eh1
                                             from eh in eh1.DefaultIfEmpty()
                                             join ceh in _dbContext.Set<CaseEvent>()
                                                 on new { CaseId = c.Id, EventNo = eh.Id, Cycle = eh.NumberOfCyclesAllowed == 1 ? 1 : instructionCycle, IsOccurredFlag = true }
                                                 equals new { ceh.CaseId, ceh.EventNo, Cycle = (int)ceh.Cycle, IsOccurredFlag = ceh.IsOccurredFlag > 0 }
                                                 into ceh1
                                             from ceh in cea1.DefaultIfEmpty()
                                             join ef in _dbContext.Set<Event>()
                                                 on r.FireEventNo equals ef.Id into ef1
                                             from ef in ef1.DefaultIfEmpty()
                                             join t in _dbContext.Set<TableCode>().Where(_ => _.TableTypeId == (int)TableTypes.NoteSharingGroup)
                                                 on ef.NoteGroupId equals t.Id into t1
                                             from t in t1.DefaultIfEmpty()
                                             where r.DefinitionId == instructionDefinitionKey
                                                   && (r.DisplayEventNo == null || cea.EventNo == null)
                                                   && (r.HideEventNo == null || ceh.EventNo == null)
                                             select new CaseInstructionResponse
                                             {
                                                 EventNo = r.FireEventNo,
                                                 EventName = ef != null ? DbFuncs.GetTranslation(null, ef.Description, ef.DescriptionTId, culture) : string.Empty,
                                                 EventNotesGroup = t != null ? DbFuncs.GetTranslation(null, t.Name, t.NameTId, culture) : string.Empty,
                                                 ResponseSequence = r.SequenceNo.ToString(),
                                                 ResponseLabel = DbFuncs.GetTranslation(null, r.Label, r.LabelTId, culture),
                                                 ResponseExplanation = DbFuncs.GetTranslation(null, r.Explanation, r.ExplanationTId, culture)
                                             }).ToListAsync();

            result.AddRange(instructionResponse);
            return result;
        }
    }

    public class CaseInstruction
    {
        public string InstructionName { get; set; }
        public string InstructionExplanation { get; set; }
        public int CaseKey { get; set; }
        public int InstructionCycle { get; set; }
        public int InstructionDefinitionKey { get; set; }
        public List<CaseInstructionResponse> Actions { get; set; }
        public string ResponseNo { get; set; }
    }

    public class CaseInstructionResponse
    {
        public int? EventNo { get; set; }
        public string EventName { get; set; }
        public string EventNotesGroup { get; set; }
        public string ResponseSequence { get; set; }

        public string ResponseLabel { get; set; }

        public string ResponseExplanation { get; set; }

    }

    public class InstructionsRequest
    {
        public ProvideInstructionList ProvideInstruction { get; set; }
        public string TaskPlannerRowKey { get; set; }
    }

    [XmlRoot(ElementName = "Instructions")]
    public class ProvideInstructionList
    {
        [XmlElement(ElementName = "Instruction")]
        public List<Instruction> Instructions { get; set; }
        [XmlElement(ElementName = "InstructionDate")]
        public string InstructionDate { get; set; }
    }

    [XmlRoot(ElementName = "Instruction")]
    public class Instruction
    {
        [XmlElement(ElementName = "CaseKey")]
        public int CaseKey { get; set; }
        [XmlElement(ElementName = "InstructionCycle")]
        public int InstructionCycle { get; set; }
        [XmlElement(ElementName = "InstructionDefinitionKey")]
        public string InstructionDefinitionKey { get; set; }
        [XmlElement(ElementName = "ResponseNo")]
        public string ResponseNo { get; set; }
        [XmlElement(ElementName = "ResponseLabel")]
        public string ResponseLabel { get; set; }
        [XmlIgnore]
        public FireEvent SelectedAction { get; set; }
    }

    public class EventNote
    {
        public string EventText { get; set; }
        public short? NoteType { get; set; }
    }

    public class FireEvent
    {
        public int EventNo { get; set; }
        public IEnumerable<EventNote> EventNotes { get; set; }
    }
}
