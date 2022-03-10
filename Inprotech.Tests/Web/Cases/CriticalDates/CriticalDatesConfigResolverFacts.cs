using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.CriticalDates
{
    public class CriticalDatesConfigResolverFacts : FactBase
    {
        public CriticalDatesConfigResolverFacts()
        {
            var @case = new CaseBuilder().Build().In(Db);
            _caseId = @case.Id;
            _caseRef = @case.Irn;
        }

        readonly ICriteriaReader _criteriaReader = Substitute.For<ICriteriaReader>();
        readonly IImportanceLevelResolver _importanceLevelResolver = Substitute.For<IImportanceLevelResolver>();
        readonly ISiteControlReader _siteControlReader = Substitute.For<ISiteControlReader>();

        readonly int _caseId;
        readonly string _caseRef;

        CriticalDatesConfigResolver CreateSubject()
        {
            return new CriticalDatesConfigResolver(Db, _criteriaReader, _siteControlReader, _importanceLevelResolver);
        }

        [Fact]
        public void ShouldIndicateResolutionCompleteIfCriticalDetailsAvailable()
        {
            Assert.True(new CriticalDatesMetadata
            {
                CriteriaNo = Fixture.Integer(),
                Action = Fixture.String()
            }.IsComplete);
        }

        [Fact]
        public void ShouldIndicateResolutionIncompleteIfUnableToResolveCriteria()
        {
            Assert.False(new CriticalDatesMetadata
            {
                CriteriaNo = null,
                Action = Fixture.String()
            }.IsComplete);
        }

        [Fact]
        public void ShouldIndicateResolutionIncompleteIfUnableToResolveCriticalDatesAction()
        {
            Assert.False(new CriticalDatesMetadata
            {
                CriteriaNo = Fixture.Integer(),
                Action = null
            }.IsComplete);
        }

        [Fact]
        public async Task ShouldResolveCriteriaForTheCaseAndAction()
        {
            var user = new User(Fixture.String(), Fixture.Boolean());

            var criticalDatesAction = Fixture.String();

            var criteriaToReturn = Fixture.Integer();

            _siteControlReader.Read<string>(SiteControls.CriticalDates_Internal)
                              .Returns(criticalDatesAction);

            _siteControlReader.Read<string>(SiteControls.CriticalDates_External)
                              .Returns(criticalDatesAction);

            int? criteriaIdReturned;
            _criteriaReader.TryGetEventControl(_caseId, criticalDatesAction, out criteriaIdReturned)
                           .Returns(x =>
                           {
                               x[2] = (int?) criteriaToReturn;
                               return true;
                           });

            var result = new CriticalDatesMetadata
            {
                CaseId = _caseId
            };

            await CreateSubject().Resolve(user, Fixture.String(), result);

            Assert.Equal(criteriaToReturn, result.CriteriaNo);
            Assert.Equal(_caseId, result.CaseId);
            Assert.Equal(_caseRef, result.CaseRef);
            Assert.Equal(criticalDatesAction, result.Action);
        }

        [Fact]
        public async Task ShouldResolveCriticalDatesActionForExternalUser()
        {
            const bool isExternalUser = true;

            var externalUser = new User(Fixture.String(), isExternalUser);

            var criticalDatesAction = Fixture.String();

            _siteControlReader.Read<string>(SiteControls.CriticalDates_External)
                              .Returns(criticalDatesAction);

            var result = new CriticalDatesMetadata
            {
                CaseId = _caseId
            };

            await CreateSubject().Resolve(externalUser, Fixture.String(), result);

            Assert.Equal(criticalDatesAction, result.Action);
        }

        [Fact]
        public async Task ShouldResolveCriticalDatesActionForInternalUser()
        {
            const bool isExternalUser = false;

            var internalUser = new User(Fixture.String(), isExternalUser);

            var criticalDatesAction = Fixture.String();

            _siteControlReader.Read<string>(SiteControls.CriticalDates_Internal)
                              .Returns(criticalDatesAction);

            var result = new CriticalDatesMetadata
            {
                CaseId = _caseId
            };

            await CreateSubject().Resolve(internalUser, Fixture.String(), result);

            Assert.Equal(criticalDatesAction, result.Action);
        }

        [Fact]
        public async Task ShouldResolveImportanceLevel()
        {
            var user = new User(Fixture.String(), Fixture.Boolean());

            var importanceLevelForTheUser = Fixture.Integer();

            var result = new CriticalDatesMetadata
            {
                CaseId = _caseId
            };

            _importanceLevelResolver.Resolve(user).Returns(importanceLevelForTheUser);

            await CreateSubject().Resolve(user, Fixture.String(), result);

            Assert.Equal(importanceLevelForTheUser, result.ImportanceLevel);
        }

        [Fact]
        public async Task ShouldResolveMainRenewalAction()
        {
            var user = new User(Fixture.String(), Fixture.Boolean());

            var mainRenewalAction = Fixture.String();

            _siteControlReader.Read<string>(SiteControls.MainRenewalAction)
                              .Returns(mainRenewalAction);

            var result = new CriticalDatesMetadata {CaseId = _caseId};

            await CreateSubject().Resolve(user, Fixture.String(), result);

            Assert.Equal(mainRenewalAction, result.RenewalAction);
        }

        [Fact]
        public async Task ShouldThrowWhenResultNotProvided()
        {
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await CreateSubject().Resolve(new User(), Fixture.String(), null));
        }

        [Fact]
        public async Task ShouldThrowWhenUserNotProvided()
        {
            await Assert.ThrowsAsync<ArgumentNullException>(async () => await CreateSubject().Resolve(null, Fixture.String(), new CriticalDatesMetadata()));
        }
    }
}