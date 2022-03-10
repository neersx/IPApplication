using System.Linq;
using Inprotech.Integration.CaseSource.Uspto;
using InprotechKaizen.Model.Integration.PtoAccess;
using Xunit;

namespace Inprotech.Tests.Integration.CaseSource.Uspto
{
    public class TsdrSourceRestrictorFacts
    {
        [Theory]
        [InlineData(1, "12345", null, "23456")]
        [InlineData(1, "12345", null, "")]
        [InlineData(1, "", null, "23456")]
        [InlineData(0, "", null, null)]
        public void OnlyEligibleCasesWithRequiredNumbersAreReturned(
            int expectedReturnCount,
            string applicationNumber,
            string publicationNumber,
            string registrationNumber)
        {
            var source = new[]
            {
                new EligibleCaseItem
                {
                    ApplicationNumber = applicationNumber,
                    PublicationNumber = publicationNumber,
                    RegistrationNumber = registrationNumber
                }
            }.AsQueryable();

            var r = new TsdrSourceRestrictor().Restrict(source);

            Assert.Equal(expectedReturnCount, r.Count());
        }
    }
}