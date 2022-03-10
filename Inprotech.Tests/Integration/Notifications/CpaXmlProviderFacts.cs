using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Notifications;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class CpaXmlProviderFacts
    {
        [Fact]
        public async Task CallsIntegrationServerToRetrieveCpaXml()
        {
            var cpaxml = Fixture.String();
            var notificationId = Fixture.Integer();

            var integrationServer = Substitute.For<IIntegrationServerClient>();
            integrationServer.DownloadString("api/dataextract/storage/cpaxml?notificationId=" + notificationId)
                             .Returns(cpaxml);

            var subject = new CpaXmlProvider(integrationServer);
            var r = await subject.For(notificationId);

            Assert.Equal(cpaxml, r);
        }
    }
}