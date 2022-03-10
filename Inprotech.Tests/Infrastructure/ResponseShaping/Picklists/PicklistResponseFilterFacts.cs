using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.ResponseShaping.Picklists
{
    public class PicklistResponseFilterFacts
    {
        public enum ResponseType
        {
            OtherTypesOfPayload,
            PicklistPayload
        }

        public class OnActionExecutedMethod
        {
            [Theory]
            [InlineData("Stream")]
            [InlineData("String")]
            public async Task IgnoresOtherContentTypes(string contentType)
            {
                var f = new PicklistResopnseFilterFixture();

                var c = contentType == "String"
                    ? (HttpContent) new StringContent("blah")
                    : new StreamContent(new MemoryStream(new byte[0]));

                var actionExecutedContext = f.CreateActionExecutedContext(c, ResponseType.PicklistPayload);

                await f.Subject.OnActionExecutedAsync(actionExecutedContext, CancellationToken.None);

                Assert.Equal(c, actionExecutedContext.Response.Content);
            }

            [Fact]
            public async Task CallsEachEnricher()
            {
                var f = new PicklistResopnseFilterFixture();

                var d = new AnyPayload();

                var c = new ObjectContent(d.GetType(), d, new JsonMediaTypeFormatter());

                var actionExecutedContext = f.CreateActionExecutedContext(c, ResponseType.PicklistPayload);

                await f.Subject.OnActionExecutedAsync(actionExecutedContext, CancellationToken.None);

                f.PicklistPayloadData1.Received(1).Enrich(actionExecutedContext, Arg.Any<Dictionary<string, object>>());

                f.PicklistPayloadData2.Received(1).Enrich(actionExecutedContext, Arg.Any<Dictionary<string, object>>());
            }

            [Fact]
            public async Task EnrichesFindApiResponseWithStandardName()
            {
                // restmod.$find();
                var f = new PicklistResopnseFilterFixture();

                var d = new AnyPayload();

                var c = new ObjectContent(d.GetType(), d, new JsonMediaTypeFormatter());

                var actionExecutedContext = f.CreateActionExecutedContext(c, ResponseType.PicklistPayload);

                await f.Subject.OnActionExecutedAsync(actionExecutedContext, CancellationToken.None);

                var replacementContent = ((ObjectContent) actionExecutedContext.Response.Content).Value;

                Assert.IsType<Dictionary<string, object>>(replacementContent);
                Assert.Equal(d, ((Dictionary<string, object>) replacementContent)["data"]);
            }

            [Fact]
            public async Task EnrichesSearchApiResponseWithStandardName()
            {
                // restmod.$search();
                var f = new PicklistResopnseFilterFixture();

                var d = Enumerable.Empty<AnyPayload>();

                var c = new ObjectContent(d.GetType(), d, new JsonMediaTypeFormatter());

                var actionExecutedContext = f.CreateActionExecutedContext(c, ResponseType.PicklistPayload);

                await f.Subject.OnActionExecutedAsync(actionExecutedContext, CancellationToken.None);

                var replacementContent = ((ObjectContent) actionExecutedContext.Response.Content).Value;

                Assert.IsType<Dictionary<string, object>>(replacementContent);
                Assert.Equal(d, ((Dictionary<string, object>) replacementContent)["data"]);
            }
        }

        public class PicklistResopnseFilterFixture : IFixture<PicklistResponseFilter>
        {
            public PicklistResopnseFilterFixture()
            {
                PicklistPayloadData1 = Substitute.For<IPicklistPayloadData>();

                PicklistPayloadData2 = Substitute.For<IPicklistPayloadData>();

                Subject = new PicklistResponseFilter(new[] {PicklistPayloadData1, PicklistPayloadData2});
            }

            public IPicklistPayloadData PicklistPayloadData1 { get; set; }

            public IPicklistPayloadData PicklistPayloadData2 { get; set; }

            public PicklistResponseFilter Subject { get; }

            public HttpActionExecutedContext CreateActionExecutedContext(HttpContent content,
                                                                         ResponseType isPicklistPayload)
            {
                var whichMethod = isPicklistPayload == ResponseType.PicklistPayload
                    ? "DecoratedMethod"
                    : "NotDecoratedMethod";

                var actionDescriptor = new ReflectedHttpActionDescriptor
                {
                    MethodInfo = typeof(PicklistResopnseFilterFixture).GetMethod(whichMethod)
                };

                var actionContext = new HttpActionContext(new HttpControllerContext(), actionDescriptor);

                return new HttpActionExecutedContext(actionContext, null)
                {
                    Response = new HttpResponseMessage
                    {
                        Content = content
                    }
                };
            }

            public void NotDecoratedMethod()
            {
            }

            [PicklistPayload(typeof(AnyPayload))]
            public void DecoratedMethod()
            {
            }
        }

        public class AnyPayload
        {
        }
    }
}