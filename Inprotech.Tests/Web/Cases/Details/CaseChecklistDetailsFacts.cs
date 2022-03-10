using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Documents;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;
using Name = InprotechKaizen.Model.Names.Name;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseChecklistDetailsFacts : FactBase
    {        
        [Fact]
        public async Task ReturnsCpaChecklistData()
        {
            const int caseId = 100;

            var f = new CaseChecklistDetailsFixture();
            f.ChecklistFakeData.WithCaseDetails(caseId)
                    .WithValidChecklistData(caseId);

            var result = await f.Subject.GetChecklistTypes(caseId);
            Assert.Equal(2, result.ChecklistTypes.Count());
            Assert.True(result.ChecklistTypes.First().ChecklistTypeDescription.StartsWith("a"));
        }

        [Fact]
        public async Task ReturnsChecklistQuestionData()
        {
            const int caseId = 100;
            const int criteriaId = -1;
            const int tableCodeId = 2;
            string periodTypeKey = Fixture.String();
            string question = Fixture.String();

            var f = new CaseChecklistDetailsFixture();
            f.ChecklistFakeData.BuildCriteria(criteriaId)
             .WithTableType(tableCodeId, periodTypeKey, null)
             .WithValidChecklistData(caseId)
             .WithQuestion(criteriaId, 10, "Aaa", 3, caseId, null, false, tableCodeId, 1, 1, (decimal)1.0, 5, 10, null, null, null)
             .WithQuestion(criteriaId, 20, question, 1, caseId, null, false, tableCodeId, 1, 1, (decimal)1.0, 5, 10, null, null, null)
             .WithQuestion(criteriaId, 30, "Ccc", 2, caseId, null, false, tableCodeId, 1, 1, (decimal)1.0, 5, 10, null, null, null, 20);

            var result = (await f.Subject.GetChecklistData(caseId, criteriaId)).ToList();
            Assert.Equal(3, result.Count);
            Assert.Equal(question, result[0].Question);
            Assert.Equal(question, result[1].SourceQuestion);
        }

        [Fact]
        public async Task ReturnsChecklistQuestionWithRequiredData()
        {
            const int caseId = 100;
            const int criteriaId = -1;
            const int tableCodeId = 2;
            int nameId = 1;
            string periodTypeKey = Fixture.String();

            var f = new CaseChecklistDetailsFixture();
            f.ChecklistFakeData.BuildCriteria(criteriaId)
             .WithTableType(tableCodeId, periodTypeKey, null)
             .WithName(nameId, "aaa", "bbb")
             .WithValidChecklistData(caseId)
             .WithQuestion(criteriaId, 10, "Aaa", 3, caseId, nameId, true, tableCodeId, 1, 1, (decimal)1.0, 5, 10, null, null, null)
             .WithQuestion(criteriaId, 20, "Bbb", 1, caseId, null, false, tableCodeId, 1, 1, (decimal)1.0, 5, 10, null, null, null)
             .WithQuestion(criteriaId, 30, "Ccc", 2, caseId, null, false, tableCodeId, 1, 1, (decimal)0.0, 5, 10, null, null, null)
             .WithQuestion(criteriaId, 40, "Ddd", 5, caseId, null, false, null, 1, 1, (decimal)1.0, 5, 10, null, null, null)
             .WithQuestion(criteriaId, 50, "Eee", 4, caseId, null, false, null, 1, 1, (decimal)0.0, 5, 10, null, null, null);

            var result = (await f.Subject.GetChecklistData(caseId, criteriaId)).ToList();
            Assert.Equal(5, result.Count);
            Assert.Equal(nameId, result[2].StaffNameKey);
            Assert.Equal((decimal)0.0, result[1].IsProcessed);
            Assert.Null(result[3].PeriodTypeKey);
            Assert.NotNull(result[0].ListSelectionKey);
            Assert.True(result[0].ListSelectionTypeDescription.StartsWith("Period"));

            Assert.NotNull(result[0].ListSelectionTypeId);
            Assert.NotEqual(0, result[0].ListSelectionType.Count);
        }

        [Fact]
        public async Task ReturnsChecklistQuestionWithAmountAndValue()
        {
            const int caseId = 100;
            const int criteriaId = -1;
            const int tableCodeId = 2;
            int nameId = 1;
            string periodTypeKey = Fixture.String();

            var f = new CaseChecklistDetailsFixture();
            f.ChecklistFakeData.BuildCriteria(criteriaId)
             .WithTableType(tableCodeId, periodTypeKey, null)
             .WithName(nameId, "aaa", "bbb")
             .WithValidChecklistData(caseId)
             .WithQuestion(criteriaId, 10, "Aaa", 3, caseId, nameId, true, tableCodeId, 1, 1, (decimal) 1.0, 5, 10, null, null, null);
       
            var result = (await f.Subject.GetChecklistData(caseId, criteriaId)).ToList();
            Assert.Equal(1, result.Count);
            Assert.True(result[0].YesAnswer);
            Assert.True(result[0].IsAnswerRequired);
            Assert.Equal(5, result[0].CountValue);
            Assert.Equal(10, result[0].AmountValue);
        }

        [Fact]
        public async Task ReturnsChecklistQuestionWithDueDate()
        {
            const int caseId = 100;
            const int criteriaId = -1;
            const int tableCodeId = 2;
            const int eventId = 11;
            const int enteredDeadline = 23;
            int nameId = 1;
            string periodTypeKey = Fixture.String();

            var f = new CaseChecklistDetailsFixture();
            f.ChecklistFakeData.BuildCriteria(criteriaId)
             .WithTableType(tableCodeId, periodTypeKey, null)
             .WithCaseEventData(caseId,eventId, 1, enteredDeadline)
             .WithValidChecklistData(caseId)
             .WithQuestion(criteriaId, 10, "Aaa", 3, caseId, nameId, true, tableCodeId, 1, 1, (decimal) 1.0, 5, 10, null, null, eventId);
       
            var result = (await f.Subject.GetChecklistData(caseId, criteriaId)).ToList();
            Assert.Equal(1, result.Count);
            Assert.True(result[0].YesAnswer);
            Assert.True(result[0].IsAnswered);
            Assert.NotNull(result[0].DateValue);
            Assert.Equal(enteredDeadline, result[0].CountValue);
        }

        [Fact]
        public async Task ReturnsChecklistQuestionWithMaxCycleEventWithPeriod()
        {
            const int caseId = 100;
            const int criteriaId = -1;
            const int tableCodeId = 2;
            const int eventId = 11;
            const int enteredDeadline = 23;
            int nameId = 1;
            string periodTypeKey = "M";
            string periodTypeString = "Months";

            var f = new CaseChecklistDetailsFixture();
            f.ChecklistFakeData.BuildCriteria(criteriaId)
             .WithTableType(tableCodeId, periodTypeKey, periodTypeString)
             .WithCaseEventData(caseId,eventId, 1, enteredDeadline, periodTypeKey)
             .WithCaseEventData(caseId,eventId, 2, enteredDeadline + 1, periodTypeKey)
             .WithCaseEventData(caseId,eventId, 3, enteredDeadline + 2, periodTypeKey)
             .WithValidChecklistData(caseId)
             .WithQuestion(criteriaId, 10, "Aaa", 3, caseId, nameId, false, tableCodeId, 1, 1, (decimal) 1.0, 5, 10, null, null, eventId);
       
            var result = (await f.Subject.GetChecklistData(caseId, criteriaId)).ToList();
            Assert.Equal(enteredDeadline + 2, result[0].CountValue);
            Assert.NotNull(result[0].PeriodTypeKey);
            Assert.Equal(periodTypeKey, result[0].PeriodTypeKey);
            Assert.Equal(periodTypeString, result[0].PeriodTypeDescription);
        }

        [Fact]
        public async Task ReturnsChecklistQuestionWithProcessingInformation()
        {
            const int caseId = 100;
            const int criteriaId = -1;
            const int tableCodeId = 2;
            const int ansSourceYes = 6;
            const int ansSourceNo = 7;
            string periodTypeKey = Fixture.String();
            string question = Fixture.String();

            var checklistEvent = new EventBuilder
            {
                Description = Fixture.String(),
                Code = Fixture.RandomString(3)
            }.Build();

            var f = new CaseChecklistDetailsFixture();
            f.ChecklistFakeData.BuildCriteria(criteriaId)
             .WithTableType(tableCodeId, periodTypeKey, null)
             .WithValidChecklistData(caseId)
             .WithQuestion(criteriaId, 10, "Aaa", 3, caseId, null, false, tableCodeId, 1, 1, (decimal)1.0, 5, 10, null, null, null)
             .WithQuestion(criteriaId, 20, question, 1, caseId, null, false, tableCodeId, 1, 1, (decimal)1.0, 5, 10, null, null, null)
             .WithQuestion(criteriaId, 30, "Ccc", 2, caseId, null, false, tableCodeId, 1, 1, (decimal)1.0, 5, 10, null, null, null, 20, ansSourceYes, ansSourceNo)
             .WithCaseEventData(caseId, checklistEvent.Id, 1);

            var result = (await f.Subject.GetChecklistData(caseId, criteriaId)).ToList();
            Assert.Equal(3, result.Count);
            Assert.Equal(question, result[0].Question);
            Assert.Equal(question, result[1].SourceQuestion);
            Assert.Equal(ansSourceYes, result[1].AnswerSourceYes);
            Assert.Equal(ansSourceNo, result[1].AnswerSourceNo);
        }

        [Fact]
        public async Task ReturnsChecklistQuestionWithInstructions()
        {
            const int caseId = 100;
            const int criteriaId = -1;
            var instructions = Fixture.String();

            var f = new CaseChecklistDetailsFixture();
            f.ChecklistFakeData.BuildCriteria(criteriaId)
             .WithQuestion(criteriaId, 10, Fixture.RandomString(50), 3, caseId, null, false, null, 0, 0, 0, 0, 0, null, null, null, null, null, null, instructions);
       
            var result = (await f.Subject.GetChecklistData(caseId, criteriaId)).ToList();
            Assert.Equal(instructions, result[0].Instructions);
        }

        [Fact]
        public async Task ReturnsChecklistDocuments()
        {
            const int caseId = 100;
            var checklistCriteriaKey = Fixture.Integer();
            var f = new CaseChecklistDetailsFixture();
            f.ChecklistFakeData.WithChecklistDocuments(checklistCriteriaKey);

            var result = await f.Subject.GetChecklistDocuments(caseId, checklistCriteriaKey);
            Assert.Equal(1, result.ToList().Count);
        }
    }

    public class CaseChecklistDetailsFixture : IFixture<ICaseChecklistDetails>
    {
        public CaseChecklistDetailsFixture()
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            DbContext = new InMemoryDbContext();
            SecurityContext = Substitute.For<ISecurityContext>();
            SecurityContext.User.Returns(new User(Fixture.String(), false));
            Now = Substitute.For<Func<DateTime>>();
            PreferredCultureResolver.Resolve().Returns(string.Empty);
            DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
            Subject = new CaseChecklistDetails(DbContext, PreferredCultureResolver, SecurityContext, Now, DisplayFormattedName);
            ChecklistFakeData = new ChecklistFakeData(DbContext);
        }
        
        public ICaseChecklistDetails Subject { get; }
        IPreferredCultureResolver PreferredCultureResolver { get; }
        ISecurityContext SecurityContext { get; }
        InMemoryDbContext DbContext { get; }
        Func<DateTime> Now {get;}
        IDisplayFormattedName DisplayFormattedName { get; set; }
        public ChecklistFakeData ChecklistFakeData { get; }
    }

    public class ChecklistFakeData
    {
        readonly InMemoryDbContext _db;
        public ChecklistFakeData(InMemoryDbContext db)
        {
            _db = db;
        }

        public ChecklistFakeData BuildCriteria(int criteriaId)
        {
            new CriteriaBuilder { Id = criteriaId}.Build().In(_db);
            return this;
        }

        public ChecklistFakeData WithName(int nameId, string firstName, string secondName)
        {
            new Name(nameId){FirstName = firstName, LastName = secondName, NameCode = nameId.ToString()}.In(_db);
            return this;
        }

        public ChecklistFakeData WithCaseDetails(int caseId)
        {
            new CaseBuilder
            {
                Property = new CasePropertyBuilder().Build().In(_db),
                CaseType = new CaseTypeBuilder().Build().In(_db),
                Country = new CountryBuilder().Build().In(_db)
            }
            .BuildWithId(caseId)
            .In(_db);

            _db.SaveChanges();

            return this;
        }

        public ChecklistFakeData WithChecklistDocuments(int checklistCriteriaKey)
        {
            var documentOne = new DocumentBuilder().Build().In(_db);
            new ChecklistLetter
            {
                CriteriaId = checklistCriteriaKey,
                LetterNo = documentOne.Id
            }.In(_db);

            return this;
        }

        public ChecklistFakeData WithQuestion(int criteriaId, short questionId, string questionString, short? sequence, int caseId, int? nameId, bool hasEmployee,int? tableCodeId, int yesNoAnswer,
                                                    int yesNoRequired, decimal processedFlag, int countAnswer, int valueAnswer, decimal? dueDateFlag, int? noAnswerEventId, int? yesAnswerEventId,
                                                    short? sourceQuestion = null, short? answerSourceYes = null, short? answerSourceNo = null, string instructions = null)
        {
            var criteria = _db.Set<Criteria>().FirstOrDefault(_ => _.Id == criteriaId);
            var question = new QuestionBuilder { Id = questionId, QuestionString = questionString, YesNoRequired = 1, Instructions = instructions}.Build((int) TableTypes.PeriodType).In(_db);
            new ChecklistItem { Question = question.QuestionString, QuestionId = questionId, SequenceNo = sequence, Criteria = criteria, NoAnsweredEventId = noAnswerEventId, YesAnsweredEventId = yesAnswerEventId, DueDateFlag = dueDateFlag, YesNoRequired = yesNoRequired, SourceQuestion = sourceQuestion, AnswerSourceYes = answerSourceYes, AnswerSourceNo = answerSourceNo}.In(_db);
            new CaseChecklist (1, caseId, questionId)
            { 
                EmployeeId = hasEmployee ? nameId : null, 
                ProcessedFlag = processedFlag,
                TableCode = tableCodeId,
                YesNoAnswer = yesNoAnswer,
                ValueAnswer = valueAnswer,
                CountAnswer = countAnswer,
                ChecklistText = Fixture.String(),
                ProductCode = 1,
            }.In(_db);
            
            return this;
        }

        public ChecklistFakeData WithCaseEventData(int caseId,int mappedEventId, short? cycle, int? enteredDeadline = null, string periodTypeId = null, string code = null)
        {
            new CaseEventBuilder
                {
                    CaseId = caseId,
                    EventNo = mappedEventId,
                    Cycle = cycle,
                    EventDate = Fixture.PastDate(),
                    EnteredDeadline = enteredDeadline,
                    PeriodTypeId = periodTypeId
                }.Build()
                 .In(_db);
            
            return this;
        }

        public ChecklistFakeData WithValidChecklistData(int caseId)
        {
            var caseData = _db.Set<Case>().FirstOrDefault(_ => _.Id == caseId);

            if (caseData == null) return this;
            new ValidChecklist {PropertyTypeId = caseData.PropertyTypeId, CaseTypeId = caseData.TypeId, CountryId = caseData.CountryId, ChecklistType = 1, ChecklistDescription = "b" + Fixture.String()}.In(_db);
            new ValidChecklist {PropertyTypeId = caseData.PropertyTypeId, CaseTypeId = caseData.TypeId, CountryId = caseData.CountryId, ChecklistType = 2, ChecklistDescription = "a" + Fixture.String()}.In(_db);

            return this;
        }

        public ChecklistFakeData WithTableType(int tableCodeId, string periodTypeKey, string periodTypeString)
        {
            var tableType = new TableType {Id = (int) TableTypes.PeriodType, DatabaseTable = "Period", Name = Fixture.String("Period type")}.In(_db);
            new TableCode {Id = tableCodeId, TableTypeId = tableType.Id, UserCode = periodTypeKey, Name = periodTypeString}.In(_db);
            return this;
        }
    }
}