using System.Linq;
using Inprotech.Integration.CaseSource.Epo;
using Inprotech.Integration.Schedules;
using InprotechKaizen.Model.Integration.PtoAccess;
using Xunit;

namespace Inprotech.Tests.Integration.CaseSource.Epo
{
    public class EpoSourceRestrictorFacts
    {
        [Theory]
        [InlineData(1, "12345", "5784", "")]
        [InlineData(1, "12345", "", "")]
        [InlineData(1, "", "23456", "")]
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

            var r = new EpoSourceRestrictor().Restrict(source, DownloadType.All);

            Assert.Equal(expectedReturnCount, r.Count());
        }
    }
}