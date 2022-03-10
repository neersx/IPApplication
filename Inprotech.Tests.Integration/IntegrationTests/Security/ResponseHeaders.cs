using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Security
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class ResponseHeaders : IntegrationTest
    {
        [Test]
        public void CheckResponseHeaders()
        {
            using (var response = ApiClient.GetResponse("picklists/jurisdictions"))
            {
                Assert.AreEqual(response.Headers.Get("X-Frame-Options"), "SameOrigin");
                Assert.AreEqual(response.Headers.Get("X-XSS-Protection"), "1; mode=block");
                Assert.AreEqual(response.Headers.Get("X-Content-Type-Options"), "nosniff");
                Assert.AreEqual(response.Headers.Get("Content-Security-Policy"), "default-src 'self'");
            }
        }
    }
}