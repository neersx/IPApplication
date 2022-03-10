using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class StatusPicklistControllerFacts : FactBase
    {
        [Theory]
        [InlineData(null)]
        [InlineData(true)]
        [InlineData(false)]
        public void ForwardParametersCorrectly(bool? renewalFlag)
        {
            var f = new StatusPicklistControllerFixture();

            f.CaseStatuses.Get(null, null, null).ReturnsForAnyArgs(new StatusListItem[0]);

            var caseType = Fixture.String();
            var propertyType = Fixture.String();
            var jurisdiction = Fixture.String();

            f.Subject.Statuses(null, string.Empty, jurisdiction, propertyType, caseType, renewalFlag);

            f.CaseStatuses.Received(1).Get(caseType, Arg.Is<string[]>(_ => _.Contains(jurisdiction)), Arg.Is<string[]>(_ => _.Contains(propertyType)), renewalFlag);
        }

        [Fact]
        public void MarksExactMatch()
        {
            var f = new StatusPicklistControllerFixture();

            var s1 = new StatusListItem {IsRenewal = false, StatusKey = 1, StatusDescription = "abcdef"};
            var s2 = new StatusListItem {IsRenewal = false, StatusKey = 2, StatusDescription = "abc"};

            f.CaseStatuses.Get(null, null, null).ReturnsForAnyArgs(new[] {s1, s2});

            var r = f.Subject.Statuses(null, "abc");

            var j = r.Data.OfType<Status>().ToArray();

            Assert.Equal(2, j.Length);
            Assert.Equal(s2.StatusDescription, j.First().Value);
        }

        [Fact]
        public void ReturnsPagedResults()
        {
            var f = new StatusPicklistControllerFixture();

            var s1 = new StatusListItem {IsRenewal = false, StatusKey = 1, StatusDescription = "abc"};
            var s2 = new StatusListItem {IsRenewal = false, StatusKey = 2, StatusDescription = "zzz"};
            var s3 = new StatusListItem {IsRenewal = false, StatusKey = 3, StatusDescription = "fgh"};

            f.CaseStatuses.Get(null, null, null).ReturnsForAnyArgs(new[] {s1, s2, s3});

            var qParams = new CommonQueryParameters {SortBy = "Value", SortDir = "asc", Skip = 1, Take = 1};
            var r = f.Subject.Statuses(qParams);
            var statuses = r.Data.OfType<Status>().ToArray();

            Assert.Equal(3, r.Pagination.Total);
            Assert.Single(statuses);
            Assert.Equal(s3.StatusKey, statuses.Single().Key);
        }

        [Fact]
        public void ReturnsStatusesContainingSearchStringOrderedByDescription()
        {
            var f = new StatusPicklistControllerFixture();

            var s1 = new StatusListItem {IsRenewal = false, StatusKey = 1, StatusDescription = "abc"};
            var s2 = new StatusListItem {IsRenewal = false, StatusKey = 2, StatusDescription = "zzz"};
            var s3 = new StatusListItem {IsRenewal = false, StatusKey = 3, StatusDescription = "fgh"};
            var s4 = new StatusListItem {IsRenewal = false, StatusKey = 3, StatusDescription = "bdc"};

            f.CaseStatuses.Get(null, null, null).ReturnsForAnyArgs(new[] {s1, s2, s3, s4});

            var j = f.Subject.Statuses(null, "b").Data.OfType<Status>().ToArray();

            Assert.Equal(2, j.Length);
            Assert.Equal(s4.StatusKey, j.First().Key);
            Assert.Equal(s1.StatusKey, j.Last().Key);
        }

        [Fact]
        public void SearchesForStatusCode()
        {
            var f = new StatusPicklistControllerFixture();

            var s1 = new StatusListItem {IsRenewal = false, StatusKey = 1, StatusDescription = "abcdef"};
            var s2 = new StatusListItem {IsRenewal = false, StatusKey = 2, StatusDescription = "abc"};

            f.CaseStatuses.Get(null, null, null).ReturnsForAnyArgs(new[] {s1, s2});

            var r = f.Subject.Statuses(null, s2.StatusKey.ToString());

            var j = (Status[]) r.Data;

            Assert.Single(j);
            Assert.Equal(s2.StatusDescription, j.Single().Value);
        }

        [Fact]
        public void SearchesForStatusCodeAndDescription()
        {
            var f = new StatusPicklistControllerFixture();

            var s1 = new StatusListItem {IsRenewal = false, StatusKey = 1, StatusDescription = "abcdef2"};
            var s2 = new StatusListItem {IsRenewal = false, StatusKey = 2, StatusDescription = "abc"};
            var s3 = new StatusListItem {IsRenewal = false, StatusKey = 3, StatusDescription = "def"};

            f.CaseStatuses.Get(null, null, null).ReturnsForAnyArgs(new[] {s1, s2, s3});

            var r = f.Subject.Statuses(null, s2.StatusKey.ToString());

            var j = (Status[]) r.Data;

            Assert.Equal(2, j.Length);
            Assert.DoesNotContain(j, _ => _.Value.Equals(s3.StatusDescription));
        }

        [Fact]
        public void SearchesForOtherStatusProperties()
        {
            var f = new StatusPicklistControllerFixture();

            var s1 = new StatusListItem {IsRenewal = false, StatusKey = 1, StatusDescription = "abcdef2", IsConfirmationRequired = true, IsPending = true};
            var s2 = new StatusListItem {IsRenewal = false, StatusKey = 2, StatusDescription = "abc", IsRegistered = true, IsDead = true};

            f.CaseStatuses.Get(null, null, null).ReturnsForAnyArgs(new[] {s1, s2});

            var r = f.Subject.Statuses(null, s2.StatusKey.ToString());

            var j = (Status[]) r.Data;

            Assert.Equal(2, j.Length);
            Assert.True(j.First().IsPending);
            Assert.True(j.First().IsConfirmationRequired);
            Assert.True(j.Last().IsRegistered);
            Assert.True(j.Last().IsDead);
        }

        [Fact]
        public void ShouldBeDecoratedWithPicklistPayloadAttribute()
        {
            var subjectType = new StatusPicklistControllerFixture().Subject.GetType();
            var picklistAttribute =
                subjectType.GetMethod("Statuses").GetCustomAttribute<PicklistPayloadAttribute>();

            Assert.NotNull(picklistAttribute);
            Assert.Equal("Status", picklistAttribute.Name);
        }

        [Fact]
        public void ValidStatusCalledCorrectly()
        {
            var f = new StatusPicklistControllerFixture();
            var jurisdiction = Fixture.String();
            var caseType = Fixture.String();
            var propertyType = Fixture.String();
            var isRenewal = Fixture.Boolean();

            f.Subject.IsValid(Fixture.Short(), jurisdiction, caseType, propertyType, isRenewal);

            f.CaseStatuses.Received(1).IsValid(Arg.Any<short>(), Arg.Any<string>(), Arg.Any<string[]>(), Arg.Any<string[]>(), Arg.Any<bool?>());
        }
    }

    public class StatusPicklistControllerFixture : IFixture<StatusPicklistController>
    {
        public StatusPicklistControllerFixture()
        {
            CaseStatuses = Substitute.For<ICaseStatuses>();

            Subject = new StatusPicklistController(CaseStatuses);
        }

        public ICaseStatuses CaseStatuses { get; set; }

        public StatusPicklistController Subject { get; }
    }
}