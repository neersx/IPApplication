using System.Globalization;
using System.Web.Http;
using Inprotech.Web.Properties;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts
{
    public class BatchEventUpdateControllerFacts
    {
        public class PostMethod : FactBase
        {
            [Fact]
            public void RedirectsWithTempStorageId()
            {
                var fixture = new BatchEventUpdateControllerFixture(Db);
                dynamic d = new {caseIds = fixture.ExistingCase.Id.ToString(CultureInfo.InvariantCulture)};
                var jobject = new JObject {["caseIds"] = d.caseIds};
                var response = fixture.Subject.Post(jobject);

                Assert.Contains("batcheventupdate", response.Headers.Location.AbsoluteUri.ToLower());
            }

            [Fact]
            public void ThrowsWhenCaseIdListIsNotProvided()
            {
                var exception = Assert.Throws<HttpResponseException>(
                                                                     () =>
                                                                     {
                                                                         var fixture = new BatchEventUpdateControllerFixture(Db);

                                                                         dynamic d = new {caseIds = string.Empty};
                                                                         var jobject = new JObject {["caseIds"] = d.caseIds};

                                                                         fixture.Subject.Post(jobject);
                                                                     });

                Assert.Equal(Resources.ValidationAtLeastOneCaseIdMustBeSpecified, exception.Response.ReasonPhrase);
            }

            [Fact]
            public void RedirectsWithTempStorageIdInAngular()
            {
                var fixture = new BatchEventUpdateControllerFixture(Db);
                dynamic d = new {caseIds = fixture.ExistingCase.Id.ToString(CultureInfo.InvariantCulture)};
                var jobject = new JObject {["caseIds"] = d.caseIds};
                var response = fixture.SubjectInAngular.BatchEventUpdate(jobject).ToString();

                Assert.Contains("BatchEventUpdate", response);
            }
        }
    }
}