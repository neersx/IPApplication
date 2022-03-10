using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search.CaseSupportData;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.CaseSupportData
{
    public class RenewalStatusesFacts : FactBase
    {
        public RenewalStatusesFacts()
        {
            _fixture = new RenewalStatusesFixture();
            _fixture.WithUser(new UserBuilder(Db) {IsExternalUser = true}.Build())
                    .WithCulture(string.Empty);
        }

        readonly RenewalStatusesFixture _fixture;

        [Theory]
        [InlineData(true, true, true, true, null)]
        [InlineData(false, true, false, null, true)]
        [InlineData(true, false, false, true, null)]
        [InlineData(false, false, true, false, null)]
        [InlineData(true, false, true, true, null)]
        public void ShouldFilterStatus(
            bool selectionIsPending,
            bool selectionIsRegistered,
            bool selectionIsDead,
            bool? liveFlag,
            bool? registeredFlag)
        {
            _fixture.WithSqlResults(
                                    BuildRenewalStatus(
                                                       1,
                                                       liveFlag: liveFlag,
                                                       registeredFlag: registeredFlag));

            var r = _fixture.Subject.Get(
                                         string.Empty,
                                         selectionIsPending,
                                         selectionIsRegistered,
                                         selectionIsDead).Single();

            Assert.Equal(1, r.Key);
        }

        public static ExternalRenewalStatusListItem BuildRenewalStatus(
            int key = 0,
            string description = null,
            bool? liveFlag = null,
            bool? registeredFlag = null)
        {
            return new RenewalStatusListItemBuilder
                {
                    StatusKey = key,
                    StatusDescription = description ?? string.Empty,
                    LiveFlag = liveFlag,
                    RegisteredFlag = registeredFlag
                }
                .Build();
        }

        [Fact]
        public void ShouldFilterDescription()
        {
            _fixture.WithSqlResults(
                                    BuildRenewalStatus(1, "abc"));

            var r = _fixture.Subject.Get("a", false, false, false).Single();

            Assert.Equal(1, r.Key);
        }

        [Fact]
        public void ShouldSortByDescription()
        {
            _fixture.WithSqlResults(BuildRenewalStatus(description: "z"), BuildRenewalStatus(description: "a"));

            var r = _fixture.Subject.Get(string.Empty, false, false, false).ToArray();

            Assert.Equal("a", r[0].Value);
            Assert.Equal("z", r[1].Value);
        }

        [Fact]
        public void ShouldUseCasesStatusesIfIsNotExternalUser()
        {
            _fixture.WithUser(new UserBuilder(Db) {IsExternalUser = false}.Build());

            _fixture.Subject.Get("a", true, true, true);

            _fixture.CaseStatuses.Received(1).Get("a", true, true, true, true);
        }
    }

    public class RenewalStatusesFixture : FixtureBase, IFixture<IRenewalStatuses>
    {
        public RenewalStatusesFixture()
        {
            CaseStatuses = Substitute.For<ICaseStatuses>();
        }

        public ICaseStatuses CaseStatuses { get; set; }

        public IRenewalStatuses Subject => new RenewalStatuses(
                                                               DbContext,
                                                               SecurityContext,
                                                               PreferredCultureResolver,
                                                               CaseStatuses);
    }
}