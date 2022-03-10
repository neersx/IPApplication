using System.Linq;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Integration.PtoAccess;
using Xunit;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp
{
    public class FileInstructAllowedCasesFacts : FactBase
    {
        [Theory]
        [InlineData(IpTypes.TrademarkDirect, KnownRelations.EarliestPriority, KnownPropertyTypes.TradeMark)]
        [InlineData(IpTypes.DirectPatent, KnownRelations.EarliestPriority, KnownPropertyTypes.Patent)]
        public void ShouldIndicateCaseHasBeenFiledIfIntegrationExistsAgainstCase(string ipType, string relationship, string propertyType)
        {
            var parentCaseId = Fixture.Integer();
            var fileIntegrationEvent = Fixture.Integer();

            var relationshipCode = new CaseRelation(relationship, null).In(Db);

            var @case = new CaseBuilder
            {
                PropertyType = new PropertyType(propertyType, propertyType).In(Db),
                CountryCode = "AU"
            }.Build().In(Db);

            new RelatedCase(@case.Id, null, null, relationshipCode, parentCaseId).In(Db);

            new EligibleCaseItem
            {
                CaseKey = @case.Id,
                CountryCode = "AU",
                SystemCode = "FILE"
            }.In(Db);

            new FileCaseEntity
            {
                CaseId = @case.Id,
                CountryCode = "AU",
                IpType = ipType,
                ParentCaseId = parentCaseId
            }.In(Db);

            var subject = new FileInstructAllowedCases(Db);

            var r = subject.Retrieve(new FileSettings
            {
                IsEnabled = true,
                DesignatedCountryRelationship = KnownRelations.DesignatedCountry1,
                EarliestPriorityRelationship = KnownRelations.EarliestPriority,
                FileIntegrationEvent = fileIntegrationEvent
            }).Single();

            Assert.Equal(@case.Id, r.CaseId);
            Assert.Equal(parentCaseId, r.ParentCaseId);
            Assert.Equal("AU", r.CountryCode);
            Assert.True(r.Filed);
        }

        [Theory]
        [InlineData(IpTypes.TrademarkDirect, KnownRelations.EarliestPriority, KnownPropertyTypes.TradeMark)]
        [InlineData(IpTypes.DirectPatent, KnownRelations.EarliestPriority, KnownPropertyTypes.Patent)]
#pragma warning disable xUnit1026
        public void ShouldReturnEarliestPriorityBasedOnRelationshipEvent(string ipType, string relationship, string propertyType)
#pragma warning restore xUnit1026
        {
            var parentCaseId = Fixture.Integer();
            var fileIntegrationEvent = Fixture.Integer();

            var fromEvent = new EventBuilder().Build().In(Db);

            var relationshipCode = new CaseRelation(relationship, fromEvent.Id).In(Db);

            var @case = new CaseBuilder
            {
                PropertyType = new PropertyType(propertyType, propertyType).In(Db),
                CountryCode = "AU"
            }.Build().In(Db);

            new RelatedCase(@case.Id, null, null, relationshipCode, parentCaseId).In(Db);

            new CaseEventBuilder
            {
                CaseId = parentCaseId,
                Cycle = 1,
                Event = fromEvent,
                EventDate = Fixture.Today()
            }.Build().In(Db);

            new EligibleCaseItem
            {
                CaseKey = @case.Id,
                CountryCode = "AU",
                SystemCode = "FILE"
            }.In(Db);

            var subject = new FileInstructAllowedCases(Db);

            var r = subject.Retrieve(new FileSettings
            {
                IsEnabled = true,
                DesignatedCountryRelationship = KnownRelations.DesignatedCountry1,
                EarliestPriorityRelationship = KnownRelations.EarliestPriority,
                FileIntegrationEvent = fileIntegrationEvent
            }).Single();

            Assert.Equal(Fixture.Today(), r.EarliestPriority);
        }

        [Fact]
        public void ShouldExcludeCasesWithoutDc1Relationship()
        {
            var caseId = Fixture.Integer();
            var pctCaseId = Fixture.Integer();

            var other = new CaseRelation(Fixture.String(), null).In(Db);

            new RelatedCase(pctCaseId, null, null, other, caseId).In(Db);

            new EligibleCaseItem
            {
                CaseKey = caseId,
                CountryCode = "AU",
                SystemCode = "FILE"
            }.In(Db);

            var subject = new FileInstructAllowedCases(Db);

            Assert.Empty(subject.Retrieve(new FileSettings
            {
                IsEnabled = true
            }));
        }

        [Fact]
        public void ShouldExcludeNonEligibleCases()
        {
            var caseId = Fixture.Integer();
            var pctCaseId = Fixture.Integer();

            var dc1 = new CaseRelation(KnownRelations.DesignatedCountry1, null).In(Db);

            new RelatedCase(pctCaseId, null, null, dc1, caseId).In(Db);

            var subject = new FileInstructAllowedCases(Db);

            Assert.Empty(subject.Retrieve(new FileSettings
            {
                IsEnabled = true
            }));
        }

        [Fact]
        public void ShouldReturnEmptyResultSetIfNotEnabled()
        {
            var subject = new FileInstructAllowedCases(Db);

            var r = subject.Retrieve(new FileSettings
            {
                IsEnabled = false
            });

            Assert.Empty(r);
        }
    }
}