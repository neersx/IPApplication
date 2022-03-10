using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Serialization;
using Inprotech.Tests.Fakes;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.ProvideInstructions;
using Inprotech.Web.Search;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model.Components.Cases.Reminders;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ProvideInstructions
{
    public class ProvideInstructionManagerFacts : FactBase
    {
        [Fact]
        public async Task InstructShouldThrowArgumentNullException()
        {
            var fixture = new ProvideInstructionManagerFixture();
            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.Instruct(new InstructionsRequest()); });
        }

        [Fact]
        public async Task VerifyGetInstructions()
        {
            var fixture = new ProvideInstructionManagerFixture();
            var taskPlannerKey = "C^34^78";
            var taskDetail = new TaskDetails() { CaseKey = Fixture.Integer(), Cycle = Fixture.Short(), EventNo = Fixture.Integer(), EventDescription = Fixture.String(), DueDate = DateTime.Today };
            var instructionDefinitionKey = Fixture.Integer();
            var instructionName = Fixture.String();
            var searchResult = new SearchResult()
            {
                Rows = new List<Dictionary<string, object>>()
                {
                    new()
                    {
                        {"InstructionCycle", Fixture.Integer()},
                        {"InstructionDefinitionKey", instructionDefinitionKey},
                        {"instructiondefinition", new { value = instructionName}},
                        {"InstructionExplanationAny", Fixture.String()}
                    }
                }
            };

            fixture.TaskPlannerDetailsResolver.Resolve(Arg.Any<string>())
                   .Returns(taskDetail);
            fixture.SearchService.RunSearch(Arg.Any<SearchRequestParams<ProvideInstructionsRequestFilter>>())
                   .Returns(searchResult);
            var r = await fixture.Subject.GetInstructions(taskPlannerKey);
            Assert.Equal(taskDetail.EventDescription, r.EventText);
            Assert.Equal(taskDetail.DueDate, r.EventDueDate);
            var instructions = r.Instructions as List<CaseInstruction>;
            Assert.Equal(instructionDefinitionKey, instructions?.First().InstructionDefinitionKey);
            Assert.Equal(instructionName, instructions?.First().InstructionName);
        }
    }

    public class ProvideInstructionManagerFixture : IFixture<ProvideInstructionManager>
    {
        public ProvideInstructionManagerFixture(InMemoryDbContext db = null)
        {
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            ReminderManager = Substitute.For<IReminderManager>();
            SecurityContext = Substitute.For<ISecurityContext>();
            SearchService = Substitute.For<ISearchService>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            SerializeXml = Substitute.For<ISerializeXml>();
            TaskPlannerDetailsResolver = Substitute.For<ITaskPlannerDetailsResolver>();
            EventNotesResolver = Substitute.For<IEventNotesResolver>();
            Subject = new ProvideInstructionManager(DbContext,
                                                    PreferredCultureResolver,
                                                    ReminderManager,
                                                    SearchService,
                                                    SecurityContext, 
                                                    SerializeXml, 
                                                    TaskPlannerDetailsResolver,
                                                    EventNotesResolver);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }

        public IDbContext DbContext { get; set; }
        public IReminderManager ReminderManager { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public ISearchService SearchService { get; set; }
        public ISerializeXml SerializeXml { get; set; }
        public ITaskPlannerDetailsResolver TaskPlannerDetailsResolver { get; set; }
        public IEventNotesResolver EventNotesResolver { get; set; }
        public ProvideInstructionManager Subject { get; }
    }
}