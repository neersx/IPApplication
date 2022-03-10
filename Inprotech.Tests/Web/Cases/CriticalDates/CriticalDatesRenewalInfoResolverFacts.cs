using System;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.CriticalDates
{
    public class CriticalDatesRenewalInfoResolverFacts
    {
        readonly INextRenewalDatesResolver _nextRenewalDatesResolver = Substitute.For<INextRenewalDatesResolver>();

        readonly User _user = new User(Fixture.String(), Fixture.Boolean());
        readonly string _culture = Fixture.String();

        CriticalDatesRenewalInfoResolver CreateSubject()
        {
            return new CriticalDatesRenewalInfoResolver(_nextRenewalDatesResolver);
        }

        [Fact]
        public async Task ShouldCallNextRenewalDateResolver()
        {
            var metadata = new CriticalDatesMetadata
            {
                CaseId = Fixture.Integer(),
                CriteriaNo = Fixture.Integer()
            };

            var expectedRenewalDate = Fixture.PastDate();
            var expectedCpaRenewalDate = Fixture.FutureDate();
            var expectedAgeOfCase = Fixture.Short();

            _nextRenewalDatesResolver.Resolve(metadata.CaseId, metadata.CriteriaNo)
                                     .Returns(new RenewalDates
                                     {
                                         AgeOfCase = expectedAgeOfCase,
                                         NextRenewalDate = expectedRenewalDate,
                                         CpaRenewalDate = expectedCpaRenewalDate
                                     });

            await CreateSubject().Resolve(_user, _culture, metadata);

            Assert.Equal(expectedAgeOfCase, metadata.AgeOfCase);
            Assert.Equal(expectedCpaRenewalDate, metadata.CpaRenewalDate);
            Assert.Equal(expectedRenewalDate, metadata.NextRenewalDate);
        }

        [Fact]
        public async Task ShouldThrowIfCriteriaNotProvided()
        {
            var metadata = new CriticalDatesMetadata {CriteriaNo = null};

            var exception = await Assert.ThrowsAsync<ArgumentException>(async () => await CreateSubject().Resolve(_user, _culture, metadata));

            Assert.Equal("CriteriaNo must be provided", exception.Message);
        }

        [Fact]
        public async Task ShouldThrowIfMetadataNotProvided()
        {
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await CreateSubject().Resolve(_user, _culture, null));
        }
    }
}