using System.Web.Http;
using Inprotech.Web.Properties;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts
{
    public class WhenCaseidListIsNotProvided : FactBase
    {
        readonly BatchEventUpdateControllerFixture _fixture;

        public WhenCaseidListIsNotProvided()
        {
            _fixture = new BatchEventUpdateControllerFixture(Db);

            try
            {
                dynamic d = new { caseIds = string.Empty };
                var jobject = new JObject();
                jobject["caseIds"] = d.caseIds;
                _fixture.Subject.Post(jobject);
            }
            catch (HttpResponseException ex)
            {
                _fixture.Exception = ex;
            }
        }

        [Fact]
        public void It_should_redirected_to_batcheventupdatecontroller_with_tempstorage_id()
        {
            Assert.True(((HttpResponseException)_fixture.Exception).Response.ReasonPhrase == Resources.ValidationAtLeastOneCaseIdMustBeSpecified);
        }
    }

}
