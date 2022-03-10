using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class QuestionsPicklistControllerFacts : FactBase
    {
        public class SearchMethod : FactBase
        {
            [Fact]
            public async Task ReturnsPagedResults()
            {
                var f = new QuestionsPicklistControllerFixture(Db);

                new Question(Fixture.Short(), "C") { Code = "A" }.In(Db);
                new Question(Fixture.Short(), "Z") { Code = "A" }.In(Db);
                var match = new Question(Fixture.Short(), "A") { Code = "A" }.In(Db);

                var qParams = new CommonQueryParameters { SortBy = "Question", SortDir = "asc", Skip = 0, Take = 1 };
                var r = await f.Subject.Search(qParams);
                var questions = r.Data.OfType<QuestionItem>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(questions);
                Assert.Equal(match.Id, questions.Single().Key);
            }

            [Fact]
            public async Task ReturnsQuestionsContainingSearchString()
            {
                var f = new QuestionsPicklistControllerFixture(Db);

                new Question(Fixture.Short(), Fixture.String("ABC-xyz")) { Code = "A" }.In(Db);
                new Question(Fixture.Short(), Fixture.String("123-abc")) { Code = "A" }.In(Db);
                new Question(Fixture.Short(), Fixture.RandomString(10) + "ABC") { Code = "A" }.In(Db);
                new Question(Fixture.Short(), "XYZ 123 aa nbb cc") { Code = "A" }.In(Db);

                var result = await f.Subject.Search(null, "abc");
                var questions = result.Data.OfType<QuestionItem>().ToArray();

                Assert.Equal(3, questions.Length);
            }

            [Fact]
            public async Task ReturnsQuestionsWithCodeContainingSearchString()
            {
                var f = new QuestionsPicklistControllerFixture(Db);

                new Question(Fixture.Short(), Fixture.String("123-xyz")) { Code = "A" }.In(Db);
                new Question(Fixture.Short(), Fixture.String("345-xyz")) { Code = "B" }.In(Db);
                new Question(Fixture.Short(), Fixture.RandomString(10) + "XYZ") { Code = "C" }.In(Db);
                new Question(Fixture.Short(), "XYZ 123 aa nbb cc") { Code = "ABC" }.In(Db);

                var result = await f.Subject.Search(null, "abc");
                var questions = result.Data.OfType<QuestionItem>().ToArray();

                Assert.Equal(1, questions.Length);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionIfNoMatchingQuestion()
            {
                var f = new QuestionsPicklistControllerFixture(Db);
                await Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.Update(Fixture.Integer(), new QuestionModel()));
            }

            [Fact]
            public async Task UpdatesQuestions()
            {
                var changes = new QuestionModel
                {
                    Amount = Fixture.Short(6),
                    Code = Fixture.RandomString(10),
                    Count = 2,
                    ListType = Fixture.Short(100),
                    Period = Fixture.Short(6),
                    Question = Fixture.String(),
                    Staff = Fixture.Short(6),
                    Text = Fixture.Short(6),
                    YesNo = Fixture.Short(6),
                    Instructions = Fixture.String()
                };
                var question1 = new QuestionBuilder
                    {
                        Id = Fixture.Short(),
                        QuestionString = Fixture.String("The question is "),
                        YesNoRequired = 2
                    }.Build((short)TableTypes.Circulars)
                     .In(Db);
                var f = new QuestionsPicklistControllerFixture(Db);
                var result = await f.Subject.Update(question1.Id, changes);
                Assert.Equal("success", result.Result);
                Assert.Equal(question1.Id, result.Key);
                Assert.Equal(question1.Id, result.UpdatedId);

                Assert.NotNull(Db.Set<Question>()
                                 .Single(_ => _.Id == question1.Id && 
                                              _.Code == changes.Code &&
                                              _.AmountRequired == changes.Amount &&
                                              _.CountRequired == changes.Count &&
                                              _.TableType == changes.ListType &&
                                              _.PeriodTypeRequired == changes.Period &&
                                              _.QuestionString == changes.Question &&
                                              _.EmployeeRequired == changes.Staff &&
                                              _.TextRequired == changes.Text && 
                                              _.YesNoRequired == changes.YesNo &&
                                              _.Instructions == changes.Instructions));
            }   
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeleteQuestion()
            {
                var question = new QuestionBuilder
                {
                    Id = Fixture.Short(),
                    QuestionString = Fixture.String("Delete question"),
                    YesNoRequired = 2
                }.Build((short)TableTypes.Circulars).In(Db);
                var f = new QuestionsPicklistControllerFixture(Db);
                var result = f.Subject.Delete(question.Id);
                Assert.Equal("success", result.Result);
            }

            [Fact]
            public void RaiseNotFoundErrorWhenDeletingQuestionThatDoesNotExist()
            {
                var f = new QuestionsPicklistControllerFixture(Db);

                var result = Assert.Throws<HttpResponseException>(() => f.Subject.Delete(Fixture.Short()));
                Assert.Equal(HttpStatusCode.NotFound, result.Response.StatusCode);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public async Task CreatesNewQuestionWithInternalCode()
            {
                var f = new QuestionsPicklistControllerFixture(Db);
                var newId = Fixture.Short();
                f.LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Question).Returns(newId);
                var question = new QuestionModel
                {
                    Amount = Fixture.Short(6),
                    Code = Fixture.RandomString(10),
                    Count = Fixture.Short(2),
                    ListType = Fixture.Short(100),
                    Period = Fixture.Short(6),
                    Question = Fixture.String(),
                    Staff = Fixture.Short(6),
                    Text = Fixture.Short(6),
                    YesNo = Fixture.Short(6)
                };
                var result = await f.Subject.Create(question);
                
                f.LastInternalCodeGenerator.Received(1).GenerateLastInternalCode(KnownInternalCodeTable.Question);
                Assert.NotNull(Db.Set<Question>()
                               .Single(_ => _.Id == newId && 
                                            _.Code == question.Code &&
                                            _.AmountRequired == question.Amount &&
                                            _.CountRequired == question.Count &&
                                            _.TableType == question.ListType &&
                                            _.PeriodTypeRequired == question.Period &&
                                            _.QuestionString == question.Question &&
                                            _.EmployeeRequired == question.Staff &&
                                            _.TextRequired == question.Text && 
                                            _.YesNoRequired == question.YesNo));
                Assert.Equal("success", result.Result);
                Assert.Equal(newId, result.Key);
                Assert.Equal(newId, result.UpdatedId);
            }
        }

        [Fact]
        public async Task ReturnsQuestionDetails()
        {
            var question1 = new QuestionBuilder
                {
                    Id = Fixture.Short(),
                    QuestionString = Fixture.String("The question is "),
                    YesNoRequired = 2,
                    Instructions = Fixture.String()
                }.Build((short)TableTypes.Circulars)
                 .In(Db);

            var f = new QuestionsPicklistControllerFixture(Db);
            var result = await f.Subject.Question(question1.Id);
            Assert.Equal(question1.Id, result.Key);
            Assert.Equal(question1.QuestionString, result.Question);
            Assert.Equal(question1.YesNoRequired, result.YesNo);
            Assert.Equal(question1.Instructions, result.Instructions);
        }

        [Fact]
        public async Task ReturnsViewData()
        {
            var f = new QuestionsPicklistControllerFixture(Db);
            new TableCode { Id = Fixture.Integer(), TableTypeId = (short)TableTypes.PeriodType, UserCode = "M", Name = "Months" }.In(Db);
            new TableCode(Fixture.Integer(), (short)TableTypes.PropertyType, Fixture.String("PeriodType"), Fixture.String("B")).In(Db);
            new TableCode(Fixture.Integer(), (short)TableTypes.AccountType, Fixture.String("Years"), Fixture.String("Y")).In(Db);
            new TableType(Fixture.Short()) { Name = Fixture.String("TableType") }.In(Db);

            var r = await f.Subject.GetViewData();
            Assert.Equal(2, r.PeriodTypes.Length);
            Assert.Equal(2, r.TableTypes.Length);
        }
    }

    public class QuestionsPicklistControllerFixture : IFixture<QuestionsPicklistController>
    {
        public QuestionsPicklistControllerFixture(InMemoryDbContext db)
        {
            var tableType = new TableType { Id = (int)TableTypes.PeriodType, DatabaseTable = "Period", Name = Fixture.String("Period type") }.In(db);
            new TableCode { Id = Fixture.Integer(), TableTypeId = tableType.Id, UserCode = "D", Name = "Days" }.In(db);
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            PreferredCultureResolver.Resolve().ReturnsForAnyArgs(Fixture.RandomString(2));
            StaticTranslator = Substitute.For<IStaticTranslator>();
            LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
            Subject = new QuestionsPicklistController(db, PreferredCultureResolver, StaticTranslator, LastInternalCodeGenerator);
        }

        public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }
        public IStaticTranslator StaticTranslator { get; set; }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public QuestionsPicklistController Subject { get; }
    }
}