using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

// ReSharper disable ParameterOnlyUsedForPreconditionCheck.Local

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class ActionEventNotesFacts
    {
        public class ActionIdsWithEventNotesMethod : FactBase
        {
            [Fact]
            public void ReturnsRecordsWithEventNotes()
            {
                var f = new ActionsFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var workingAction = OpenActionBuilder.ForCaseAsValid(Db, @case).Build().In(Db);
                var notWorkingAction = OpenActionBuilder.ForCaseAsValid(Db, @case).Build().In(Db);
                var validEvent = new ValidEvent(Fixture.Integer(), Fixture.Integer()).In(Db);
                validEvent.CriteriaId = Fixture.Integer();
                workingAction.CriteriaId = validEvent.CriteriaId;
                var caseEventText = new CaseEventText(@case.Id, validEvent.EventId, Fixture.Short()).In(Db);

                var r = f.Subject.ActionIdsWithEventNotes(@case.Id);
                var a = r.ToArray();

                Assert.Equal(1, a.Length);
                Assert.Equal(a[0], workingAction.ActionId);
            }
        }

        public class ActionsFixture : IFixture<ActionEventNotes>
        {
            public ActionsFixture(InMemoryDbContext db)
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User("actionUser", false, new Profile(3, "user")));
                Subject = new ActionEventNotes(db);
            }

            public ActionEventNotes Subject { get; }
        }
    }
}