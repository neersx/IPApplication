using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Keywords;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Keywords
{
    public class KeywordsControllerFacts
    {
        public class KeywordsControllerFixture : IFixture<KeywordsController>
        {
            public KeywordsControllerFixture()
            {
                Keywords = Substitute.For<IKeywords>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                Subject = new KeywordsController(Keywords, TaskSecurityProvider);
                CommonQueryParameters = CommonQueryParameters.Default;
                CommonQueryParameters.SortBy = null;
                CommonQueryParameters.SortDir = null;
            }

            public ICommonQueryService CommonQueryService { get; set; }
            public CommonQueryParameters CommonQueryParameters { get; set; }
            public IKeywords Keywords { get; set; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public KeywordsController Subject { get; set; }
        }

        public class GetKeyWords : FactBase
        {
            static List<KeywordItems> Keywords()
            {
                var data = new List<KeywordItems>
                {
                    new KeywordItems
                    {
                        KeywordNo = Fixture.Integer(),
                        KeyWord = Fixture.String("DRV"),
                        CaseStopWord = Fixture.Boolean(),
                        NameStopWord = Fixture.Boolean()
                    },
                    new KeywordItems
                    {
                        KeywordNo = Fixture.Integer(),
                        KeyWord = Fixture.String("TST"),
                        CaseStopWord = Fixture.Boolean(),
                        NameStopWord = Fixture.Boolean()
                    }
                };
                return data;
            }

            [Fact]
            public async Task ReturnsAllKeyWords()
            {
                var f = new KeywordsControllerFixture();
                var data = Keywords();
                f.Keywords.GetKeywords().Returns(data);
                var r = await f.Subject.GetKeyWords(new SearchOptions(), f.CommonQueryParameters);
                var results = r.Items<KeywordItems>().ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal(data[0].KeyWord, results[0].KeyWord);
                Assert.Equal(data[1].KeyWord, results[1].KeyWord);
            }
        }

        public class GetKeywordDetails : FactBase
        {
            [Fact]
            public async Task ShouldGetKeyword()
            {
                var f = new KeywordsControllerFixture();

                await f.Subject.GetKeyWordDetails(1);
                await f.Keywords.Received(1).GetKeywordByNo(1);
            }
        }

        public class SaveKeyword : FactBase
        {
            [Fact]
            public async Task ShouldThrowErrorInAddWhenDataNotExist()
            {
                var f = new KeywordsControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.AddKeywords(null);
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldSaveKeyword()
            {
                var f = new KeywordsControllerFixture();
                var data = new KeywordItems();
                f.Keywords.SubmitKeyWordForm(data).Returns(1);
                var result = await f.Subject.AddKeywords(data);
                Assert.Equal(result, 1);
                await f.Keywords.Received(1).SubmitKeyWordForm(data);
            }

            [Fact]
            public async Task ShouldUpdateKeyword()
            {
                var f = new KeywordsControllerFixture();
                var data = new KeywordItems
                {
                    KeywordNo = 1,
                    KeyWord = Fixture.String(),
                    CaseStopWord = Fixture.Boolean(),
                    NameStopWord = Fixture.Boolean()
                };
                f.Keywords.SubmitKeyWordForm(data).Returns(1);
                var result = await f.Subject.UpdateKeywords(data);
                Assert.Equal(result, 1);
                await f.Keywords.Received(1).SubmitKeyWordForm(data);
            }

            [Fact]
            public async Task ShouldThrowErrorInUpdateWhenDataNotExist()
            {
                var f = new KeywordsControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.UpdateKeywords(null);
                });
                Assert.IsType<ArgumentNullException>(exception);
            }
        }

        public class DeleteKeyword : FactBase
        {
            [Fact]
            public async Task ShouldDeleteKeywords()
            {
                var f = new KeywordsControllerFixture();
                f.Keywords.DeleteKeywords(Arg.Any<DeleteRequestModel>()).Returns(new DeleteResponseModel { Message = "success" });
                var response = await f.Subject.DeleteKeywords(new DeleteRequestModel());
                Assert.Equal("success", response.Message);
                await f.Keywords.Received(1).DeleteKeywords(Arg.Any<DeleteRequestModel>());
            }

            [Fact]
            public async Task ShouldReturnError()
            {
                var f = new KeywordsControllerFixture();
                f.Keywords.DeleteKeywords(Arg.Any<DeleteRequestModel>()).Throws(new HttpResponseException(HttpStatusCode.NotFound));
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () =>
                {
                    await f.Subject.DeleteKeywords(new DeleteRequestModel());
                });
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }
    }
}
