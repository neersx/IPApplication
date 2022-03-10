using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.Cases;
using Newtonsoft.Json.Linq;
using NUnit.Framework;
using Formatting = Newtonsoft.Json.Formatting;

namespace Inprotech.Tests.Integration.IntegrationTests.Cases
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class CpaXmlExport : IntegrationTest
    {
        [Test]
        public void RequestAndDownloadCpaXml()
        {
            var data = DbSetup.Do(setup => new CaseBuilder(setup.DbContext).CreateWithSummaryData());

            var requestParams = JObject.Parse("{\"queryContext\": 2,\"criteria\":{ \"searchRequest\":[{\"caseKeys\":{\"operator\":\"0\", \"value\":" + data.Case.Id + "}}]}}");

            var request = ApiClient.Post<CpaXmlResult>($"search/case/exportToCpaXml", requestParams.ToString(Formatting.None));

            Assert.NotNull(request);
            Assert.Null(request.ErrorMessage, "Request done for generating CPA-XML file");

            Try.Wait(10, 2000, IsProcessCompleted);
            if (IsProcessCompleted())
            {
                var result = ApiClient.Post($"backgroundProcess/cpaXmlExport?processId={request.BackgroundProcessId}", string.Empty);

                Assert.NotNull(result.stringResult);
                Assert.AreEqual("application/xml; charset=utf-8", result.response.ContentType);
                Assert.True(result.response.Headers["x-filename"].StartsWith("Case Import"));
            }

            bool IsProcessCompleted()
            {
                return DbSetup.Do(setup =>
                {
                    return setup.DbContext.Set<BackgroundProcess>()
                                .AsNoTracking()
                                .Count(_ => _.IdentityId == Env.LoginUserId &&
                                            _.Id == request.BackgroundProcessId &&
                                            _.Status == (int) StatusType.Completed)
                           > 0;
                });
            }
      }
    }
}