using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.ResponseEnrichment
{
    public class ResponseEnrichmentFilterFacts
    {
        public enum WithEnrichment
        {
            OptedOut,
            Default
        }

        public class ResponseEnrichmentFilterFixture : IFixture<ResponseEnrichmentFilter>
        {
            public ResponseEnrichmentFilterFixture()
            {
                ResponseEnricher1 = Substitute.For<IResponseEnricher>();

                ResponseEnricher2 = Substitute.For<IResponseEnricher>();

                Subject = new ResponseEnrichmentFilter(new[] {ResponseEnricher1, ResponseEnricher2});
            }

            public IResponseEnricher ResponseEnricher1 { get; set; }
            public IResponseEnricher ResponseEnricher2 { get; set; }

            public ResponseEnrichmentFilter Subject { get; }

            public HttpActionExecutedContext CreateActionExecutedContext(HttpContent content, WithEnrichment withEnrichment)
            {
                var whichMethod = withEnrichment == WithEnrichment.Default
                    ? "NotDecoratedMethod"
                    : "DecoratedMethod";

                var actionDescriptor = new ReflectedHttpActionDescriptor
                {
                    MethodInfo = typeof(ResponseEnrichmentFilterFixture).GetMethod(whichMethod)
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

            [NoEnrichment]
            public void DecoratedMethod()
            {
            }
        }

        public class OnActionExecutedMethod
        {
            [Theory]
            [InlineData("Stream")]
            [InlineData("String")]
            public async Task LosingOutOnEnrichmentForOtherKindsOfContent(string contentType)
            {
                var f = new ResponseEnrichmentFilterFixture();

                var c = contentType == "String"
                    ? (HttpContent) new StringContent("blah")
                    : new StreamContent(new MemoryStream(new byte[0]));

                var actionExecutedContext = f.CreateActionExecutedContext(c, WithEnrichment.Default);

                await f.Subject.OnActionExecutedAsync(actionExecutedContext, CancellationToken.None);

                Assert.Equal(c, actionExecutedContext.Response.Content);
            }

            [Fact]
            public async Task CallsEachEnricher()
            {
                var f = new ResponseEnrichmentFilterFixture();

                var d = new
                {
                    SomeRandomDynamicObject = 1
                };

                var c = new ObjectContent(d.GetType(), d, new JsonMediaTypeFormatter());

                var actionExecutedContext = f.CreateActionExecutedContext(c, WithEnrichment.Default);

                await f.Subject.OnActionExecutedAsync(actionExecutedContext, CancellationToken.None);

                f.ResponseEnricher1.Received(1).Enrich(actionExecutedContext, Arg.Any<Dictionary<string, object>>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ResponseEnricher2.Received(1).Enrich(actionExecutedContext, Arg.Any<Dictionary<string, object>>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task DoesNotEnrichIfOptedOut()
            {
                var f = new ResponseEnrichmentFilterFixture();

                var d = new
                {
                    SomeRandomDynamicObject = 1
                };

                var c = new ObjectContent(d.GetType(), d, new JsonMediaTypeFormatter());

                var actionExecutedContext = f.CreateActionExecutedContext(c, WithEnrichment.OptedOut);

                await f.Subject.OnActionExecutedAsync(actionExecutedContext, CancellationToken.None);

                Assert.Equal(c, actionExecutedContext.Response.Content);

                f.ResponseEnricher1.DidNotReceive().Enrich(actionExecutedContext, Arg.Any<Dictionary<string, object>>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ResponseEnricher2.DidNotReceive().Enrich(actionExecutedContext, Arg.Any<Dictionary<string, object>>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task EnrichesObjectContentResponse()
            {
                var f = new ResponseEnrichmentFilterFixture();

                var d = new
                {
                    SomeRandomDynamicObject = 1
                };

                var c = new ObjectContent(d.GetType(), d, new JsonMediaTypeFormatter());

                var actionExecutedContext = f.CreateActionExecutedContext(c, WithEnrichment.Default);

                await f.Subject.OnActionExecutedAsync(actionExecutedContext, CancellationToken.None);

                var replacementContent = ((ObjectContent) actionExecutedContext.Response.Content).Value;

                Assert.IsType<Dictionary<string, object>>(replacementContent);
                Assert.Equal(d, ((Dictionary<string, object>) replacementContent)["result"]);
            }
        }
    }
}