using System;
using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.CriticalDates
{
    public class CriticalDatesMetadataResolverFacts
    {
        readonly ICriticalDatesConfigResolver _configResolver = Substitute.For<ICriticalDatesConfigResolver>();
        readonly ICriticalDatesPriorityInfoResolver _priorityInfoResolver = Substitute.For<ICriticalDatesPriorityInfoResolver>();
        readonly ICriticalDatesRenewalInfoResolver _renewalInfoResolver = Substitute.For<ICriticalDatesRenewalInfoResolver>();

        [Fact]
        public async Task ShouldCallConfigResolver()
        {
            var user = new User(Fixture.String(), Fixture.Boolean());

            var culture = Fixture.String();

            var caseId = Fixture.Integer();

            var expected = new CriticalDatesMetadata
            {
                CaseId = caseId,
                Action = Fixture.String(),
                CriteriaNo = Fixture.Integer(),
                RenewalAction = Fixture.String(),
                ImportanceLevel = Fixture.Integer()
            };

            _configResolver.WhenForAnyArgs(x => x.Resolve(user, culture, Arg.Any<CriticalDatesMetadata>()))
                           .Do(x =>
                           {
                               var m = (CriticalDatesMetadata) x[2];

                               m.CaseId = expected.CaseId;
                               m.Action = expected.Action;
                               m.CriteriaNo = expected.CriteriaNo;
                               m.RenewalAction = expected.RenewalAction;
                               m.ImportanceLevel = expected.ImportanceLevel;
                           });

            var subject = new CriticalDatesMetadataResolver(_configResolver, _renewalInfoResolver, _priorityInfoResolver);

            var r = await subject.Resolve(user, culture, caseId);

            _configResolver.Received(1).Resolve(user, culture, Arg.Any<CriticalDatesMetadata>())
                           .IgnoreAwaitForNSubstituteAssertion();

            Assert.True(r.IsComplete);
            Assert.Equal(expected.CaseId, r.CaseId);
            Assert.Equal(expected.Action, r.Action);
            Assert.Equal(expected.CriteriaNo, r.CriteriaNo);
            Assert.Equal(expected.RenewalAction, r.RenewalAction);
            Assert.Equal(expected.ImportanceLevel, r.ImportanceLevel);
        }

        [Fact]
        public async Task ShouldCallPriorityInfoResolver()
        {
            var user = new User(Fixture.String(), Fixture.Boolean());

            var culture = Fixture.String();

            var caseId = Fixture.Integer();

            var expected = new CriticalDatesMetadata
            {
                CaseId = caseId,
                Action = Fixture.String(),
                CriteriaNo = Fixture.Integer(),
                DefaultPriorityEventNo = Fixture.Integer(),
                EarliestPriorityDate = Fixture.PastDate(),
                EarliestPriorityNumber = Fixture.String(),
                EarliestPriorityCountry = Fixture.String(),
                PriorityEventNo = Fixture.Integer()
            };

            _configResolver.WhenForAnyArgs(x => x.Resolve(user, culture, Arg.Any<CriticalDatesMetadata>()))
                           .Do(x =>
                           {
                               var m = (CriticalDatesMetadata) x[2];

                               m.CaseId = expected.CaseId;
                               m.Action = expected.Action;
                               m.CriteriaNo = expected.CriteriaNo;
                           });

            _priorityInfoResolver.WhenForAnyArgs(x => x.Resolve(user, culture, Arg.Any<CriticalDatesMetadata>()))
                                 .Do(x =>
                                 {
                                     var m = (CriticalDatesMetadata) x[2];

                                     m.DefaultPriorityEventNo = expected.DefaultPriorityEventNo;
                                     m.EarliestPriorityDate = expected.EarliestPriorityDate;
                                     m.EarliestPriorityNumber = expected.EarliestPriorityNumber;
                                     m.EarliestPriorityCountry = expected.EarliestPriorityCountry;
                                     m.PriorityEventNo = expected.PriorityEventNo;
                                 });

            var subject = new CriticalDatesMetadataResolver(_configResolver, _renewalInfoResolver, _priorityInfoResolver);

            var r = await subject.Resolve(user, culture, caseId);

            _priorityInfoResolver.Received(1).Resolve(user, culture, Arg.Any<CriticalDatesMetadata>())
                                 .IgnoreAwaitForNSubstituteAssertion();

            Assert.True(r.IsComplete);
            Assert.Equal(expected.CaseId, r.CaseId);
            Assert.Equal(expected.Action, r.Action);
            Assert.Equal(expected.CriteriaNo, r.CriteriaNo);
            Assert.Equal(expected.RenewalAction, r.RenewalAction);
            Assert.Equal(expected.ImportanceLevel, r.ImportanceLevel);
            Assert.Equal(expected.DefaultPriorityEventNo, r.DefaultPriorityEventNo);
            Assert.Equal(expected.EarliestPriorityDate, r.EarliestPriorityDate);
            Assert.Equal(expected.EarliestPriorityNumber, r.EarliestPriorityNumber);
            Assert.Equal(expected.EarliestPriorityCountry, r.EarliestPriorityCountry);
            Assert.Equal(expected.PriorityEventNo, r.PriorityEventNo);
        }

        [Fact]
        public async Task ShouldCallRenewalDatesResolver()
        {
            var user = new User(Fixture.String(), Fixture.Boolean());

            var culture = Fixture.String();

            var caseId = Fixture.Integer();

            var expected = new CriticalDatesMetadata
            {
                CaseId = caseId,
                Action = Fixture.String(),
                CriteriaNo = Fixture.Integer(),
                DefaultPriorityEventNo = Fixture.Integer(),
                NextRenewalDate = Fixture.FutureDate(),
                CpaRenewalDate = Fixture.FutureDate(),
                AgeOfCase = Fixture.Short()
            };

            _configResolver.WhenForAnyArgs(x => x.Resolve(user, culture, Arg.Any<CriticalDatesMetadata>()))
                           .Do(x =>
                           {
                               var m = (CriticalDatesMetadata) x[2];

                               m.CaseId = expected.CaseId;
                               m.Action = expected.Action;
                               m.CriteriaNo = expected.CriteriaNo;
                           });

            _renewalInfoResolver.WhenForAnyArgs(x => x.Resolve(user, culture, Arg.Any<CriticalDatesMetadata>()))
                                .Do(x =>
                                {
                                    var m = (CriticalDatesMetadata) x[2];

                                    m.NextRenewalDate = expected.NextRenewalDate;
                                    m.CpaRenewalDate = expected.CpaRenewalDate;
                                    m.AgeOfCase = expected.AgeOfCase;
                                });

            var subject = new CriticalDatesMetadataResolver(_configResolver, _renewalInfoResolver, _priorityInfoResolver);

            var r = await subject.Resolve(user, culture, caseId);

            _renewalInfoResolver.Received(1).Resolve(user, culture, Arg.Any<CriticalDatesMetadata>())
                                .IgnoreAwaitForNSubstituteAssertion();

            Assert.True(r.IsComplete);
            Assert.Equal(expected.CaseId, r.CaseId);
            Assert.Equal(expected.Action, r.Action);
            Assert.Equal(expected.CriteriaNo, r.CriteriaNo);
            Assert.Equal(expected.RenewalAction, r.RenewalAction);
            Assert.Equal(expected.ImportanceLevel, r.ImportanceLevel);

            Assert.Equal(expected.NextRenewalDate, r.NextRenewalDate);
            Assert.Equal(expected.CpaRenewalDate, r.CpaRenewalDate);
            Assert.Equal(expected.AgeOfCase, r.AgeOfCase);
        }

        [Fact]
        public async Task ShouldNotCallOtherResolverIfConfigIncomplete()
        {
            var user = new User(Fixture.String(), Fixture.Boolean());

            var culture = Fixture.String();

            var caseId = Fixture.Integer();

            var expected = new CriticalDatesMetadata
            {
                CaseId = caseId
            };

            _configResolver.WhenForAnyArgs(x => x.Resolve(user, culture, Arg.Any<CriticalDatesMetadata>()))
                           .Do(x =>
                           {
                               var m = (CriticalDatesMetadata) x[2];
                               m.CaseId = expected.CaseId;
                           });

            var subject = new CriticalDatesMetadataResolver(_configResolver, _renewalInfoResolver, _priorityInfoResolver);

            var r = await subject.Resolve(user, culture, caseId);

            _configResolver.Received(1).Resolve(user, culture, Arg.Any<CriticalDatesMetadata>())
                           .IgnoreAwaitForNSubstituteAssertion();

            _priorityInfoResolver.DidNotReceive().Resolve(user, culture, Arg.Any<CriticalDatesMetadata>())
                                 .IgnoreAwaitForNSubstituteAssertion();

            _renewalInfoResolver.DidNotReceive().Resolve(user, culture, Arg.Any<CriticalDatesMetadata>())
                                .IgnoreAwaitForNSubstituteAssertion();

            Assert.False(r.IsComplete);
            Assert.Equal(expected.CaseId, r.CaseId);
        }

        [Fact]
        public async Task ShouldThrowArgumentNullExceptionWhenUserNotProvided()
        {
            var subject = new CriticalDatesMetadataResolver(_configResolver, _renewalInfoResolver, _priorityInfoResolver);

            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await subject.Resolve(null, Fixture.String(), Fixture.Integer()); });
        }
    }
}