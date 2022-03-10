using System.Collections.Generic;
using System.Net.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Xunit;
using HeaderValue = System.Net.Http.Headers.StringWithQualityHeaderValue;

namespace Inprotech.Tests.Infrastructure.ResponseEnrichment
{
    public class UserAgentResponseEnricherFacts
    {
        public UserAgentResponseEnricherFacts()
        {
            _enrichment = new Dictionary<string, object>();

            var actionDescriptor = new ReflectedHttpActionDescriptor();

            var controllerContext = new HttpControllerContext
            {
                Request = new HttpRequestMessage()
            };

            var actionContext = new HttpActionContext(controllerContext, actionDescriptor);

            _context = new HttpActionExecutedContext(actionContext, null);
        }

        readonly HttpActionExecutedContext _context;
        readonly Dictionary<string, object> _enrichment;

        void BuildAcceptLanguages(params HeaderValue[] languages)
        {
            _context.Request.Headers.AcceptLanguage.AddAll(languages);
        }

        [Fact]
        public void ShouldReadAcceptLanguageFromRequestHttpHeaders()
        {
            BuildAcceptLanguages(new HeaderValue("a"));
            var enricher = new UserAgentResponseEnricher();

            enricher.Enrich(_context, _enrichment);
            dynamic userAgent = _enrichment["userAgent"];

            Assert.Equal("a", userAgent.Languages[0]);
        }

        [Fact]
        public void ShouldReturnLanguagesOrderedByQuality()
        {
            BuildAcceptLanguages(new HeaderValue("b", 0.5), new HeaderValue("c", 0.2), new HeaderValue("a"));
            var enricher = new UserAgentResponseEnricher();

            enricher.Enrich(_context, _enrichment);
            dynamic userAgent = _enrichment["userAgent"];

            Assert.Equal("a", userAgent.Languages[0]);
            Assert.Equal("b", userAgent.Languages[1]);
            Assert.Equal("c", userAgent.Languages[2]);
        }
    }
}