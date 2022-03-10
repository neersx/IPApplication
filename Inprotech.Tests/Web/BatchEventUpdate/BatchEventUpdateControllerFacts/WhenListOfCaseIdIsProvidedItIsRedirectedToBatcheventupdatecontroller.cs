using System;
using System.Globalization;
using System.Net;
using System.Net.Http;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts
{
    public class WhenListOfCaseIdIsProvidedItIsRedirectedToBatcheventupdatecontroller : FactBase
    {
        readonly HttpResponseMessage _response;

        public WhenListOfCaseIdIsProvidedItIsRedirectedToBatcheventupdatecontroller()
        {
            var fixture = new BatchEventUpdateControllerFixture(Db);
            dynamic d = new { caseIds = fixture.ExistingCase.Id.ToString(CultureInfo.InvariantCulture) };
            var jobject = new JObject();
            jobject["caseIds"] = d.caseIds;
            _response = fixture.Subject.Post(jobject);
        }

        [Fact]
        public void It_should_redirected_to_batcheventupdatecontroller_with_tempstorage_id()
        {
            Assert.True(_response.Headers.Location.AbsoluteUri.ToLower().Contains("batcheventupdate"));
        }

        [Fact]
        public void It_should_set_the_cache_headers()
        {
            Assert.True(_response.Headers.CacheControl.NoStore);
            Assert.True(_response.Headers.CacheControl.NoCache);
            Assert.True(_response.Headers.CacheControl.MaxAge.Equals(TimeSpan.Zero));
        }

        [Fact]
        public void It_should_set_the_status_code_to_redirect()
        {
            Assert.True(_response.StatusCode.Equals(HttpStatusCode.Redirect));
        }
    }       
}
