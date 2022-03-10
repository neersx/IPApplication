using System.Linq;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Integration.PtoAccess;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class InprotechCaseResolverFacts : FactBase
    {
        [Fact]
        public void ShouldReturnEligibleLiveCaseWithMatchingApplicationNumber()
        {
            var e = CreateCaseEligibleForSource();
            CreateCaseEligibleForSource();
            CreateCaseEligibleForSource();

            var subject = new InprotechCaseResolver(Db);

            var r = subject.ResolveUsing(e.ApplicationNumber).Single();

            Assert.Equal(e.CaseKey, r.CaseKey);
            Assert.Equal(e.ApplicationNumber, r.ApplicationNumber);
            Assert.Equal(e.PublicationNumber, r.PublicationNumber);
            Assert.Equal(e.RegistrationNumber, r.RegistrationNumber);
            Assert.Equal("USPTO.PrivatePAIR", r.SystemCode);
            Assert.Equal(e.CountryCode, r.CountryCode);

            EligibleCaseItem CreateCaseEligibleForSource()
            {
                var eligible = new EligibleCaseItem
                {
                    CaseKey = Fixture.Integer(),
                    ApplicationNumber = Fixture.String(),
                    PublicationNumber = Fixture.String(),
                    RegistrationNumber = Fixture.String(),
                    CountryCode = Fixture.String(),
                    IsLiveCase = true
                }.In(Db);

                new OfficialNumberBuilder
                    {
                        CaseId = eligible.CaseKey,
                        OfficialNo = eligible.ApplicationNumber,
                        NumberType = new NumberTypeBuilder
                        {
                            Code = KnownNumberTypes.Application
                        }.Build(),
                        IsCurrent = 1
                    }.Build()
                     .In(Db);

                new CaseIndexes
                {
                    CaseId = eligible.CaseKey,
                    GenericIndex = eligible.ApplicationNumber,
                    Source = CaseIndexSource.OfficialNumbers
                }.In(Db);
                return eligible;
            }
        }
        
        [Fact]
        public void ShouldReturnLiveCaseOnly()
        {
            var applicationNumber = Fixture.String();

            var e1 = CreateCaseEligibleForSource(applicationNumber);
            var e2 = CreateCaseEligibleForSource(applicationNumber);

            e1.IsLiveCase = true;
            e2.IsLiveCase = false;

            var subject = new InprotechCaseResolver(Db);

            var r = subject.ResolveUsing(applicationNumber).Single();

            Assert.Equal(e1.CaseKey, r.CaseKey);
            Assert.Equal(e1.ApplicationNumber, r.ApplicationNumber);
            Assert.Equal(e1.PublicationNumber, r.PublicationNumber);
            Assert.Equal(e1.RegistrationNumber, r.RegistrationNumber);
            Assert.Equal("USPTO.PrivatePAIR", r.SystemCode);
            Assert.Equal(e1.CountryCode, r.CountryCode);

            EligibleCaseItem CreateCaseEligibleForSource(string appNumber)
            {
                var eligible = new EligibleCaseItem
                {
                    CaseKey = Fixture.Integer(),
                    ApplicationNumber = appNumber,
                    PublicationNumber = Fixture.String(),
                    RegistrationNumber = Fixture.String(),
                    CountryCode = Fixture.String()
                }.In(Db);

                new OfficialNumberBuilder
                    {
                        CaseId = eligible.CaseKey,
                        OfficialNo = eligible.ApplicationNumber,
                        NumberType = new NumberTypeBuilder
                        {
                            Code = KnownNumberTypes.Application
                        }.Build(),
                        IsCurrent = 1
                    }.Build()
                     .In(Db);

                new CaseIndexes
                {
                    CaseId = eligible.CaseKey,
                    GenericIndex = eligible.ApplicationNumber,
                    Source = CaseIndexSource.OfficialNumbers
                }.In(Db);
                return eligible;
            }
        }

        [Fact]
        public void ShouldReturnItemsInOfficialNumberCaseIndexesOnly()
        {
            var e = new EligibleCaseItem
            {
                CaseKey = Fixture.Integer(),
                ApplicationNumber = Fixture.String(),
                PublicationNumber = Fixture.String(),
                RegistrationNumber = Fixture.String(),
                CountryCode = Fixture.String(),
                IsLiveCase = true
            }.In(Db);

            new OfficialNumberBuilder
                {
                    CaseId = e.CaseKey,
                    OfficialNo = e.ApplicationNumber,
                    NumberType = new NumberTypeBuilder
                    {
                        Code = KnownNumberTypes.Application
                    }.Build(),
                    IsCurrent = 1
                }.Build()
                 .In(Db);

            new CaseIndexes
            {
                CaseId = e.CaseKey,
                GenericIndex = e.ApplicationNumber,
                Source = CaseIndexSource.OfficialNumbers
            }.In(Db);

            var subject = new InprotechCaseResolver(Db);

            var r = subject.ResolveUsing(e.ApplicationNumber).Single();

            Assert.Equal(e.CaseKey, r.CaseKey);
            Assert.Equal(e.ApplicationNumber, r.ApplicationNumber);
            Assert.Equal(e.PublicationNumber, r.PublicationNumber);
            Assert.Equal(e.RegistrationNumber, r.RegistrationNumber);
            Assert.Equal("USPTO.PrivatePAIR", r.SystemCode);
            Assert.Equal(e.CountryCode, r.CountryCode);
        }

        [Fact]
        public void ShouldNotReturnIfCaseIndexesNumberIsNotAnApplicationNumber()
        {
            var e = new EligibleCaseItem
            {
                CaseKey = Fixture.Integer(),
                ApplicationNumber = Fixture.String(),
                PublicationNumber = Fixture.String(),
                RegistrationNumber = Fixture.String(),
                SystemCode = Fixture.String(),
                CountryCode = Fixture.String()
            }.In(Db);

            new OfficialNumberBuilder
                {
                    CaseId = e.CaseKey,
                    OfficialNo = e.PublicationNumber,
                    NumberType = new NumberTypeBuilder
                    {
                        Code = KnownNumberTypes.Publication
                    }.Build(),
                    IsCurrent = 1
                }.Build()
                 .In(Db);

            new OfficialNumberBuilder
                {
                    CaseId = e.CaseKey,
                    OfficialNo = e.RegistrationNumber,
                    NumberType = new NumberTypeBuilder
                    {
                        Code = KnownNumberTypes.Registration
                    }.Build(),
                    IsCurrent = 1
                }.Build()
                 .In(Db);

            new CaseIndexes
            {
                CaseId = e.CaseKey,
                GenericIndex = e.PublicationNumber,
                Source = CaseIndexSource.OfficialNumbers
            }.In(Db);

            new CaseIndexes
            {
                CaseId = e.CaseKey,
                GenericIndex = e.RegistrationNumber,
                Source = CaseIndexSource.OfficialNumbers
            }.In(Db);

            var subject = new InprotechCaseResolver(Db);

            Assert.Empty(subject.ResolveUsing(e.ApplicationNumber).ToArray());
        }

        [Fact]
        public void ShouldNotReturnIfNumberIsNotCurrent()
        {
            var e = new EligibleCaseItem
            {
                CaseKey = Fixture.Integer(),
                ApplicationNumber = Fixture.String(),
                PublicationNumber = Fixture.String(),
                RegistrationNumber = Fixture.String(),
                SystemCode = Fixture.String(),
                CountryCode = Fixture.String()
            }.In(Db);

            new OfficialNumberBuilder
                {
                    CaseId = e.CaseKey,
                    OfficialNo = e.ApplicationNumber,
                    NumberType = new NumberTypeBuilder
                    {
                        Code = KnownNumberTypes.Application
                    }.Build(),
                    IsCurrent = 0
                }.Build()
                 .In(Db);

            new CaseIndexes
            {
                CaseId = e.CaseKey,
                GenericIndex = e.ApplicationNumber,
                Source = CaseIndexSource.OfficialNumbers
            }.In(Db);

            var subject = new InprotechCaseResolver(Db);

            Assert.Empty(subject.ResolveUsing(e.ApplicationNumber).ToArray());
        }
    }
}