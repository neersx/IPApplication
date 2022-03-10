using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.CriticalDates
{
    public class CriticalDatesResolverFacts
    {
        readonly ICriticalDatesMetadataResolver _criticalDatesMetadataResolver = Substitute.For<ICriticalDatesMetadataResolver>();
        readonly IInterimCriticalDatesResolver _interimCriticalDatesResolver = Substitute.For<IInterimCriticalDatesResolver>();
        readonly IInterimLastOccurredDateResolver _interimLastOccurredDateResolver = Substitute.For<IInterimLastOccurredDateResolver>();
        readonly IInterimNextDueEventResolver _interimNextDueEventResolver = Substitute.For<IInterimNextDueEventResolver>();

        readonly int _caseId = Fixture.Integer();
        readonly string _culture = Fixture.String();

        readonly User _internalUser = new User(Fixture.String(), false);

        CriticalDatesResolver CreateSubjectFor(User user)
        {
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(user);

            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            preferredCultureResolver.Resolve().Returns(_culture);

            return new CriticalDatesResolver(_criticalDatesMetadataResolver, _interimCriticalDatesResolver, _interimLastOccurredDateResolver, _interimNextDueEventResolver, securityContext, preferredCultureResolver);
        }

        [Fact]
        public async Task ShouldCombineResultsFromAllInterimResolvers()
        {
            var meta = new CriticalDatesMetadata
            {
                CaseId = _caseId,
                CriteriaNo = Fixture.Integer(),
                Action = "CC"
            };

            var i1 = new InterimCriticalDate {CaseKey = _caseId, EventKey = Fixture.Integer()};
            var i2 = new InterimCriticalDate {CaseKey = _caseId, EventKey = Fixture.Integer()};
            var i3 = new InterimCriticalDate {CaseKey = _caseId, EventKey = Fixture.Integer()};

            _criticalDatesMetadataResolver.Resolve(_internalUser, _culture, _caseId).Returns(meta);

            _interimCriticalDatesResolver.Resolve(_internalUser, _culture, meta).Returns(new[] {i1});

            _interimLastOccurredDateResolver.Resolve(_internalUser, _culture, meta).Returns(new[] {i2});

            _interimNextDueEventResolver.Resolve(_internalUser, _culture, meta).Returns(new[] {i3});

            var r = await CreateSubjectFor(_internalUser).Resolve(_caseId);

            Assert.Equal(new[] {i1, i2, i3}.Select(_ => _.EventKey.GetValueOrDefault()),
                         r.Select(_ => _.EventKey.GetValueOrDefault()));
        }

        [Fact]
        public async Task ShouldOrderResultByCriticalDatesFollowedByNextDueThenByLastOccurred()
        {
            var meta = new CriticalDatesMetadata
            {
                CaseId = _caseId,
                CriteriaNo = Fixture.Integer(),
                Action = "CC"
            };

            var i1Last = new InterimCriticalDate {CaseKey = _caseId, EventKey = Fixture.Integer(), CountryCode = "4", DisplaySequence = 4};
            var i1First = new InterimCriticalDate {CaseKey = _caseId, EventKey = Fixture.Integer(), CountryCode = "3", DisplaySequence = 1};
            var i2 = new InterimCriticalDate {CaseKey = _caseId, EventKey = Fixture.Integer(), CountryCode = "2", IsLastOccurredEvent = true};
            var i3 = new InterimCriticalDate {CaseKey = _caseId, EventKey = Fixture.Integer(), CountryCode = "1", IsNextDueEvent = true};

            _criticalDatesMetadataResolver.Resolve(_internalUser, _culture, _caseId).Returns(meta);

            _interimCriticalDatesResolver.Resolve(_internalUser, _culture, meta).Returns(new[] {i1Last, i1First});

            _interimLastOccurredDateResolver.Resolve(_internalUser, _culture, meta).Returns(new[] {i2});

            _interimNextDueEventResolver.Resolve(_internalUser, _culture, meta).Returns(new[] {i3});

            var r = await CreateSubjectFor(_internalUser).Resolve(_caseId);

            Assert.Equal(new[] {i1First, i1Last, i3, i2}.Select(_ => _.EventKey.GetValueOrDefault()),
                         r.Select(_ => _.EventKey.GetValueOrDefault()));
        }

        [Fact]
        public async Task ShouldReturnEmptyWhenDetailsIncomplete()
        {
            _criticalDatesMetadataResolver.Resolve(_internalUser, _culture, _caseId)
                                          .Returns(new CriticalDatesMetadata {CaseId = _caseId});

            Assert.Empty(await CreateSubjectFor(_internalUser).Resolve(_caseId));
        }

        [Fact]
        public async Task ShouldReturnEverythingForTheInternalUser()
        {
            var meta = new CriticalDatesMetadata
            {
                CaseId = _caseId,
                CriteriaNo = Fixture.Integer(),
                Action = "CC"
            };

            var interimResult = new InterimCriticalDate
            {
                CaseKey = _caseId,
                EventKey = Fixture.Integer(),
                OfficialNumber = Fixture.String(),
                DisplaySequence = Fixture.Short(),
                DisplayDate = Fixture.Today(),
                EventDefinition = Fixture.String(),
                EventDescription = Fixture.String(),
                IsCPARenewalDate = Fixture.Boolean(),
                IsLastOccurredEvent = Fixture.Boolean(),
                IsNextDueEvent = Fixture.Boolean(),
                IsOccurred = Fixture.Boolean(),
                RowKey = Fixture.String(),
                RenewalYear = Fixture.Short(),
                CountryCode = Fixture.String(),
                CountryKey = Fixture.String(),
                IsPriorityEvent = Fixture.Boolean(),
                NumberTypeCode = Fixture.String(),
                ExternalPatentInfoUri = new Uri("https://innography.com")
            };

            _criticalDatesMetadataResolver.Resolve(_internalUser, _culture, _caseId).Returns(meta);

            _interimCriticalDatesResolver.Resolve(_internalUser, _culture, meta).Returns(new[] {interimResult});

            _interimLastOccurredDateResolver.Resolve(_internalUser, _culture, meta).Returns(new InterimCriticalDate[0]);

            _interimNextDueEventResolver.Resolve(_internalUser, _culture, meta).Returns(new InterimCriticalDate[0]);

            var r = (await CreateSubjectFor(_internalUser).Resolve(_caseId)).Single();

            Assert.Equal(interimResult.CaseKey, r.CaseKey);
            Assert.Equal(interimResult.EventKey, r.EventKey);
            Assert.Equal(interimResult.OfficialNumber, r.OfficialNumber);
            Assert.Equal(interimResult.DisplaySequence, r.DisplaySequence);
            Assert.Equal(interimResult.DisplayDate, r.Date);
            Assert.Equal(interimResult.EventDefinition, r.EventDefinition);
            Assert.Equal(interimResult.EventDescription, r.EventDescription);
            Assert.Equal(interimResult.IsCPARenewalDate, r.IsCpaRenewalDate);
            Assert.Equal(interimResult.IsLastOccurredEvent, r.IsLastEvent);
            Assert.Equal(interimResult.IsNextDueEvent, r.IsNextDueEvent);
            Assert.Equal(interimResult.IsOccurred, r.IsOccurred);
            Assert.Equal(interimResult.RowKey, r.RowKey);
            Assert.Equal(interimResult.RenewalYear, r.RenewalYear);
            Assert.Equal(interimResult.CountryCode, r.CountryCode);
            Assert.Equal(interimResult.CountryKey, r.CountryKey);
            Assert.Equal(interimResult.IsPriorityEvent, r.IsPriorityEvent);
            Assert.Equal(interimResult.NumberTypeCode, r.NumberTypeCode);
            Assert.Equal(interimResult.ExternalPatentInfoUri, r.ExternalInfoLink);
        }

        [Fact]
        public async Task ShouldSuppressLastOccurredIfSameEventAppearedInCriticalDates()
        {
            var meta = new CriticalDatesMetadata
            {
                CaseId = _caseId,
                CriteriaNo = Fixture.Integer(),
                Action = "CC"
            };

            var i1 = new InterimCriticalDate {CaseKey = _caseId, EventKey = 111, CountryCode = "This one"};
            var i2 = new InterimCriticalDate {CaseKey = _caseId, EventKey = 111, CountryCode = "Not this one"};

            _criticalDatesMetadataResolver.Resolve(_internalUser, _culture, _caseId).Returns(meta);

            _interimCriticalDatesResolver.Resolve(_internalUser, _culture, meta).Returns(new[] {i1});

            _interimLastOccurredDateResolver.Resolve(_internalUser, _culture, meta).Returns(new[] {i2});

            _interimNextDueEventResolver.Resolve(_internalUser, _culture, meta).Returns(new InterimCriticalDate[0]);

            var r = await CreateSubjectFor(_internalUser).Resolve(_caseId);

            Assert.Single(r);
            Assert.Equal("This one", r.Single().CountryCode);
        }
    }
}