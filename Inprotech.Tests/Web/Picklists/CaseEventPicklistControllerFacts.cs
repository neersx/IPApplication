using System.Collections.Generic;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class CaseEventPicklistControllerFacts
    {
        public class EventsMethod : FactBase
        {
            [Fact]
            public void CallMatchingItemsCorrectly()
            {
                var search = Fixture.String();
                var caseId = Fixture.Integer();
                var actionId = Fixture.RandomString(2);
                var f = new CaseEventPicklistControllerFixture();

                f.EventMatcher.MatchingItems(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<string>())
                 .Returns(new List<MatchedEvent>());

                f.Subject.Events(caseId, null, search, actionId);
                f.EventMatcher.Received(1).MatchingItems(caseId, search, actionId);
            }
        }

        public class CaseEventPicklistControllerFixture : IFixture<CaseEventPicklistController>
        {
            public CaseEventPicklistControllerFixture()
            {
                CommonQueryService = Substitute.For<ICommonQueryService>();
                EventMatcher = Substitute.For<ICaseEventMatcher>();
                Subject = new CaseEventPicklistController(CommonQueryService, EventMatcher);
            }

            public ICommonQueryService CommonQueryService { get; set; }
            public ICaseEventMatcher EventMatcher { get; set; }
            public CaseEventPicklistController Subject { get; }
        }
    }
}
