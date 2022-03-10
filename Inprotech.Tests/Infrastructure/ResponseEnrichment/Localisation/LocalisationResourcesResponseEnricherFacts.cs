using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment.Localisation;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.ResponseEnrichment.Localisation
{
    public class LocalisationResourcesResponseEnricherFacts
    {
        public enum With
        {
            IncludeLocalisationResourcesAttribute,
            NoAttribute
        }

        public class LocalisationResourcesResponseEnricherFixture : IFixture<LocalisationResourcesResponseEnricher>
        {
            public LocalisationResourcesResponseEnricherFixture()
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                LocalisationResources = Substitute.For<ILocalisationResources>();

                Subject = new LocalisationResourcesResponseEnricher(PreferredCultureResolver, LocalisationResources);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public ILocalisationResources LocalisationResources { get; set; }

            public LocalisationResourcesResponseEnricher Subject { get; }

            public HttpActionExecutedContext CreateActionExecutedContext(With with, string uri = "/api/uspto/inbox")
            {
                var whichMethod = with == With.IncludeLocalisationResourcesAttribute
                    ? "DecoratedMethod"
                    : "NotDecoratedMethod";

                var actionDescriptor = new ReflectedHttpActionDescriptor
                {
                    MethodInfo = typeof(LocalisationResourcesResponseEnricherFixture).GetMethod(whichMethod)
                };

                var controllerContext = new HttpControllerContext
                {
                    Request = new HttpRequestMessage(HttpMethod.Get, new Uri(new Uri("http://myorg/cpainpro/i"), uri))
                };

                var actionContext = new HttpActionContext(controllerContext, actionDescriptor);

                return new HttpActionExecutedContext(actionContext, null);
            }

            public void NotDecoratedMethod()
            {
            }

            [IncludeLocalisationResources]
            public void DecoratedMethod()
            {
            }
        }

        public class EnrichMethod
        {
            [Theory]
            [InlineData("/api/uspto/newschedules", "uspto")]
            [InlineData("/api/caseworkflow/select-entry", "caseworkflow")]
            [InlineData("/api/epo/file-application", "epo")]
            public void ResolvesApplicationNameFromUrl(string url, string expectedValue)
            {
                var result = new[] {expectedValue};
                var f = new LocalisationResourcesResponseEnricherFixture();

                var actionExecutedContext = f.CreateActionExecutedContext(With.IncludeLocalisationResourcesAttribute, url);

                f.Subject.Enrich(actionExecutedContext, new Dictionary<string, object>());

                f.LocalisationResources.Received(1).For(Arg.Is<IEnumerable<string>>(_ => result.SequenceEqual(_)), Arg.Any<IEnumerable<string>>());
            }

            [Fact]
            public void DoesNotEnrichWhenAttributeNotPresent()
            {
                var f = new LocalisationResourcesResponseEnricherFixture();

                var actionExecutedContext = f.CreateActionExecutedContext(With.NoAttribute);

                f.Subject.Enrich(actionExecutedContext, new Dictionary<string, object>());

                f.PreferredCultureResolver.DidNotReceive().ResolveWith(Arg.Any<HttpRequestHeaders>());

                f.LocalisationResources.DidNotReceive().For(Arg.Any<IEnumerable<string>>(), Arg.Any<IEnumerable<string>>());
            }

            [Fact]
            public void ResolvesPortalWhenApplicationNameIsNotAvailable()
            {
                var result = new[] {"portal"};
                var f = new LocalisationResourcesResponseEnricherFixture();

                var actionExecutedContext = f.CreateActionExecutedContext(With.IncludeLocalisationResourcesAttribute, "/new-schedules");

                f.Subject.Enrich(actionExecutedContext, new Dictionary<string, object>());

                f.LocalisationResources.Received(1).For(Arg.Is<IEnumerable<string>>(_ => result.SequenceEqual(_)), Arg.Any<IEnumerable<string>>());
            }

            [Fact]
            public void ReturnsResourcesFromPreferredCulture()
            {
                var f = new LocalisationResourcesResponseEnricherFixture();

                var actionExecutedContext = f.CreateActionExecutedContext(With.IncludeLocalisationResourcesAttribute);

                var candidateCultures = new[] {"en-AU", "en"};

                var resources = new Dictionary<string, object>();

                f.PreferredCultureResolver.ResolveWith(actionExecutedContext.Request.Headers).Returns(candidateCultures);

                f.LocalisationResources.For(Arg.Any<IEnumerable<string>>(), candidateCultures).Returns((object)resources);

                var context = new Dictionary<string, object>();

                f.Subject.Enrich(actionExecutedContext, context);

                Assert.Equal(resources, context["__resources"]);
            }
        }
    }
}