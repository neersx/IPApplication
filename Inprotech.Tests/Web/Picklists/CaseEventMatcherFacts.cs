using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.Translations;
using NSubstitute;
using Xunit;
using EntityModel = InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Tests.Web.Picklists
{
    public class CaseEventMatcherFacts
    {
        public class MatchingItems : FactBase
        {
            [Fact]
            public void ChecksLookupCultureOnce()
            {
                var f = new CaseEventMatcherFixture(Db);
                f.Subject.MatchingItems(Fixture.Integer(), Fixture.String());
                f.PreferredCultureResolver.Received(1).Resolve();
                f.LookupCultureResolver.Received(1).Resolve(Arg.Any<string>());
            }

            [Fact]
            public void ReturnsOnlyValidCaseEvents()
            {
                var f = new CaseEventMatcherFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var openAction = new OpenActionBuilder(Db){Case = @case, IsOpen = true}.Build().In(Db);
                var event1 = new EventBuilder { Code = "TEST", Description = Fixture.String() }.Build().In(Db);
                event1.ValidEvents = new List<ValidEvent>();
                var event2 = new EventBuilder { Code = Fixture.RandomString(3), Description = Fixture.String("TEST") }.Build().In(Db);
                event2.ValidEvents = new List<ValidEvent>();
                var event3 = new EventBuilder { Code = Fixture.RandomString(3), Description = Fixture.String("TEST") }.Build().In(Db);
                new EventBuilder { Code = Fixture.RandomString(3), Description = Fixture.String("TEST") }.Build().In(Db);
                new CaseEventBuilder { Event = event1, Cycle = 1}.BuildForCase(@case).In(Db);
                new CaseEventBuilder { Event = event2, Cycle = 1 }.BuildForCase(@case).In(Db);
                new CaseEventBuilder { Event = event3, Cycle = 2 }.BuildForCase(@case).In(Db);

                event1.ValidEvents.Add(new ValidEvent(openAction.Criteria, event1, event1.Description) { EventId = event1.Id, CriteriaId = openAction.Criteria.Id }.In(Db));
                event2.ValidEvents.Add(new ValidEvent(openAction.Criteria, event2, $"EventControl - {event2.Description}") { EventId = event2.Id, CriteriaId = openAction.Criteria.Id }.In(Db));

                f.LookupCultureResolver.Resolve(Arg.Any<string>()).Returns(new LookupCulture());

                var r = f.Subject.MatchingItems(@case.Id, "TEST").ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(event1.Id, r[0].Key);
                Assert.Equal(event1.Code, r[0].Code);
                Assert.Equal(event1.Description, r[0].Value);
                Assert.Equal(event2.Id, r[1].Key);
                Assert.Equal(event2.Code, r[1].Code);
                Assert.Equal($"EventControl - {event2.Description}", r[1].Value);
            }
        }

        class CaseEventMatcherFixture : IFixture<ICaseEventMatcher>
        {
            public CaseEventMatcherFixture(InMemoryDbContext db, string culture = null, bool isExternal = false)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                LookupCultureResolver = Substitute.For<ILookupCultureResolver>();
                LookupCulture = !string.IsNullOrEmpty(culture) ? new LookupCulture(culture, culture) : new LookupCulture();
                LookupCultureResolver.Resolve(Arg.Any<string>()).Returns(LookupCulture);
                SecurityContext = Substitute.For<ISecurityContext>();

                var user = new User("user", isExternal).In(db);
                SecurityContext.User.Returns(_ => user);

                Subject = new CaseEventMatcher(db, PreferredCultureResolver, LookupCultureResolver);
            }

            LookupCulture LookupCulture { get; set; }
            public ILookupCultureResolver LookupCultureResolver { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            ISecurityContext SecurityContext { get; }
            public ICaseEventMatcher Subject { get; }
        }
    }
}
