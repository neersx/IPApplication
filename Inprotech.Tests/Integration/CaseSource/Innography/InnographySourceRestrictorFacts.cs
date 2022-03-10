using System.Linq;
using Inprotech.Integration.CaseSource.Innography;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Integration.PtoAccess;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.CaseSource.Innography
{
    public class InnographySourceRestrictorHelper
    {
        public InMemoryDbContext Db;
        public InnographySourceRestrictorHelper(InMemoryDbContext db)
        {
            Db = db;
        }
        void CreateDatePair(string dateName, int? eventNo, string dateString, int caseId)
        {
            new SourceMappedEvents(dateName, eventNo).In(Db);
            if (string.IsNullOrWhiteSpace(dateString)) return;
            new CaseEventBuilder
                {
                    CaseId = caseId,
                    EventNo = eventNo,
                    Cycle = 1,
                    EventDate = Fixture.Date(dateString)
                }.Build()
                 .In(Db);
        }

        public int CreateMatchingEvents(string applicationDate, string publicationDate, string registrationDate)
        {
            var caseId = Fixture.Integer();
            CreateDatePair("Application", -4, applicationDate, caseId);
            CreateDatePair("Publication", -36, publicationDate, caseId);
            CreateDatePair("Registration/Grant", -8, registrationDate, caseId);

            return caseId;
        }

    }

    public class InnographyPatentSourceRestrictorFacts : FactBase
    {
#pragma warning disable xUnit1026
        [Theory]
        [InlineData(2, "12345", "2001-01-01", "", "", "", "", "Should return because a application number and date pair is available")]
        [InlineData(2, "", "", "12345", "2001-01-01", "", "", "Should return because a publication number and date pair is available")]
        [InlineData(2, "", "", "", "", "12345", "2001-01-01", "Should return because a registration number and date pair is available")]
        [InlineData(0, "12345", "", "", "", "", "", "Should not return because only application number is available")]
        [InlineData(0, "12345", "", "1332324", "", "324314", "", "Should not return because only numbers are available")]
        [InlineData(0, "", "2001-01-01", "", "", "", "", "Should not return because only application date is available")]
        [InlineData(0, "", "2001-01-01", "", "2002-02-02", "", "2003-03-03", "Should not return because only dates are available")]
        public void OnlyEligibleCasesWithAtLeastOnePairOfNumbersAndDatesAreReturned(int expectedReturnCount,
                                                                                        string applicationNumber, string applicationDate,
                                                                                        string publicationNumber, string publicationDate,
                                                                                        string registrationNumber, string registrationDate,
                                                                                        string comment)
#pragma warning restore xUnit1026
        {
            var caseId = new InnographySourceRestrictorHelper(Db).CreateMatchingEvents(applicationDate, publicationDate, registrationDate);

            var source = new[]
            {
                new EligibleCaseItem
                {
                    CaseKey = caseId,
                    ApplicationNumber = applicationNumber,
                    PublicationNumber = publicationNumber,
                    RegistrationNumber = registrationNumber,
                    PropertyType = KnownPropertyTypes.Patent
                },
                new EligibleCaseItem
                {
                    CaseKey = caseId,
                    ApplicationNumber = applicationNumber,
                    PublicationNumber = publicationNumber,
                    RegistrationNumber = registrationNumber,
                    PropertyType = KnownPropertyTypes.Patent
                }
            }.AsQueryable();

            var r = new InnographyPatentsRestrictor(new EventMappingsResolver(Db)).Restrict(source, "Innography");

            Assert.Equal(expectedReturnCount, r.Count());
        }
    }

    public class InnographyTradeMarkSourceRestrictorFacts : FactBase
    {
        [Theory]
        [InlineData(2, "12345", "56789","2001-01-01","2001-01-01", "Should return because a application number and registration number is available")]
        [InlineData(2, "12345", "","2001-01-01","", "Should return even if registration number and date not available")]
        [InlineData(2, "", "12345","","2001-01-01", "Should return even if application number and date not available")]
#pragma warning disable xUnit1026
        public void OnlyEligibleCasesWithBothApplicationAndRegistrationAreReturned(
            int expectedReturnCount, string applicationNumber,
            string registrationNumber, string applicationDate,
            string registrationDate, string comment)
#pragma warning restore xUnit1026
        {
            var caseId = new InnographySourceRestrictorHelper(Db).CreateMatchingEvents(applicationDate, null, registrationDate);

            var source = new[]
            {
                new EligibleCaseItem
                {
                    CaseKey = caseId,
                    ApplicationNumber = applicationNumber,
                    RegistrationNumber = registrationNumber,
                    PropertyType = KnownPropertyTypes.TradeMark,
                    IsLiveCase = true
                },
                new EligibleCaseItem
                {
                    CaseKey = caseId,
                    ApplicationNumber = applicationNumber,
                    RegistrationNumber = registrationNumber,
                    PropertyType = KnownPropertyTypes.TradeMark,
                    IsLiveCase = false
                }
            }.AsQueryable();
           
            var r = new InnographyTrademarksRestrictor(new EventMappingsResolver(Db),
                                                       Substitute.For<INationalCasesResolver>()).Restrict(source, "Innography");

            Assert.Equal(expectedReturnCount, r.Count());
        }
    }

    public class NationalCasesResolverFacts : FactBase
    {
        [Theory]
        [InlineData(1, "Application", true, "Should not return National case as official number is same")]
        [InlineData(1, "Registration/Grant", true, "Should not return National case as official number is same")]
        [InlineData(0, "Application", false, "Should return National case as official number is not same")]
        [InlineData(0, "Registration/Grant", false, "Should return National case as official number is not same")]
        public void FindExclusionsOfNationalCases(int count, string officialNumberType, bool officialNumberSame, string comment)
#pragma warning restore xUnit1026
        {
            var @case = new CaseBuilder().Build().In(Db);
            var case2 = new CaseBuilder().Build().In(Db);

            new RelatedCase(@case.Id, KnownRelations.DesignatedCountry1)
            {
                RelatedCaseId = case2.Id
            }.In(Db);

            var parentOfficialNo = new OfficialNumber(new NumberType(officialNumberType, Fixture.String(), null).In(Db),
                                                      @case, Fixture.String())
            {
                IsCurrent = 1
            }.In(Db);

            new OfficialNumber(new NumberType(officialNumberType, Fixture.String(), null).In(Db),
                               case2, officialNumberSame ? parentOfficialNo.Number : Fixture.String())
            {
                IsCurrent = 1
            }.In(Db);

            var r = new NationalCasesResolver(Db).FindExclusions("Innography");

            Assert.Equal(count, r.Count());
        }
    }
}