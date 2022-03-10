using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Integration.Security.Authorization;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Integration.Security.Authorization
{
    public class ExpiredAccessTokenFacts : FactBase
    {
        [Fact]
        public async Task ShouldRemoveExpiredTokens()
        {
            new OneTimeToken
            {
                ExpiryDate = Fixture.PastDate().ToUniversalTime()
            }.In(Db);

            new OneTimeToken
            {
                ExpiryDate = Fixture.FutureDate().ToUniversalTime()
            }.In(Db);

            await new ExpiredAccessTokens(Db, Fixture.Today).Remove();

            Assert.Single(Db.Set<OneTimeToken>());

            Assert.Equal(Fixture.FutureDate().ToUniversalTime(), Db.Set<OneTimeToken>().Single().ExpiryDate);
        }
    }
}