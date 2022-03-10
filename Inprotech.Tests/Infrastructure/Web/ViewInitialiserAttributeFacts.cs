using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Formatting;
using Inprotech.Infrastructure.Web;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Web
{
    public class ViewInitialiserAttributeFacts
    {
        public ViewInitialiserAttributeFacts()
        {
            _enrichedData = new Dictionary<string, object> {{"result", "a"}};

            _enrichedContent = new ObjectContent(
                                                 typeof(IDictionary<string, object>),
                                                 _enrichedData,
                                                 new JsonMediaTypeFormatter());
        }

        readonly IDictionary<string, object> _enrichedData;
        readonly ObjectContent _enrichedContent;

        [Theory]
        [InlineData("http://www.abc.com/a?menu=no")]
        [InlineData("http://www.abc.com/a")]
        public void ShouldNotBuildMenuIfMenuIsNotRequested(string requestUrl)
        {
            var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
            var response = new HttpResponseMessage(HttpStatusCode.OK) {Content = _enrichedContent};
            var context = new HttpActionExecutedContextBuilder(request).WithResponse(response).Build();

            var fixture = new ViewInitialiserAttributeFixture();

            fixture.Subject.OnActionExecuted(context);

            dynamic result = _enrichedData["result"];

            Assert.Null(result.Menu);

            fixture.Menu.DidNotReceive().Build();
        }

        [Fact]
        public void RewritesTheEnrichedResultIfMenuIsRequested()
        {
            var request = new HttpRequestMessage(HttpMethod.Get, "http://www.abc.com/a?menu=yes");
            var response = new HttpResponseMessage(HttpStatusCode.OK) {Content = _enrichedContent};
            var context = new HttpActionExecutedContextBuilder(request).WithResponse(response).Build();

            var menu = new object[0];
            var fixture = new ViewInitialiserAttributeFixture();

            fixture.Menu.Build().Returns(menu);

            fixture.Subject.OnActionExecuted(context);

            dynamic result = _enrichedData["result"];

            Assert.Equal(menu, result.Menu);
            Assert.Equal("a", result.ViewData);
        }

        [Fact]
        public void ShouldBuildWithSearchBar()
        {
            var request = new HttpRequestMessage(HttpMethod.Get, "http://www.abc.com/a?menu=yes");
            var response = new HttpResponseMessage(HttpStatusCode.OK) {Content = _enrichedContent};
            var context = new HttpActionExecutedContextBuilder(request).WithResponse(response).Build();

            var searchBar = new object();
            var fixture = new ViewInitialiserAttributeFixture();

            fixture.SearchBar.SearchAccess().Returns(searchBar);

            fixture.Subject.OnActionExecuted(context);

            dynamic result = _enrichedData["result"];

            Assert.Equal(searchBar, result.SearchBar);
            Assert.Equal("a", result.ViewData);
        }

        [Fact]
        public void ShouldForwardCorrectHttpRequestMessageToResolveLifetimeScope()
        {
            var request = new HttpRequestMessage(HttpMethod.Get, "http://www.abc.com/a?menu=yes");
            var response = new HttpResponseMessage(HttpStatusCode.OK) {Content = _enrichedContent};
            var context = new HttpActionExecutedContextBuilder(request).WithResponse(response).Build();

            var fixture = new ViewInitialiserAttributeFixture();

            fixture.Subject.OnActionExecuted(context);

            fixture.CurrentRequestLifetimeScope.Received(1).Resolve<IMenu>(request);
            fixture.CurrentRequestLifetimeScope.Received(1).Resolve<ISearchBar>(request);
        }

        [Fact]
        public void ShouldIgnoreExceptionResponse()
        {
            var request = new HttpRequestMessage(HttpMethod.Get, "http://www.abc.com/a?menu=yes");
            var context = new HttpActionExecutedContextBuilder(request).WithException(new Exception()).Build();

            var fixture = new ViewInitialiserAttributeFixture();

            fixture.Subject.OnActionExecuted(context);

            fixture.Menu.DidNotReceive().Build();
        }

        [Fact]
        public void ShouldIgnoreResponseWithoutOkStatus()
        {
            var request = new HttpRequestMessage(HttpMethod.Get, "http://www.abc.com/a?menu=yes");
            var response = new HttpResponseMessage(HttpStatusCode.NotFound);
            var context = new HttpActionExecutedContextBuilder(request).WithResponse(response).Build();

            var fixture = new ViewInitialiserAttributeFixture();

            fixture.Subject.OnActionExecuted(context);

            fixture.Menu.DidNotReceive().Build();
        }
    }

    public class ViewInitialiserAttributeFixture : IFixture<ViewInitialiserAttribute>
    {
        public ViewInitialiserAttributeFixture()
        {
            Menu = Substitute.For<IMenu>();
            SearchBar = Substitute.For<ISearchBar>();
            CurrentRequestLifetimeScope = Substitute.For<ICurrentRequestLifetimeScope>();
            CurrentRequestLifetimeScope.Resolve<IMenu>(null).ReturnsForAnyArgs(Menu);
            CurrentRequestLifetimeScope.Resolve<ISearchBar>(null).ReturnsForAnyArgs(SearchBar);
        }

        public IMenu Menu { get; set; }
        public ISearchBar SearchBar { get; set; }

        public ICurrentRequestLifetimeScope CurrentRequestLifetimeScope { get; set; }

        public ViewInitialiserAttribute Subject
        {
            get
            {
                var attribute = new ViewInitialiserAttribute {CurrentRequestLifetimeScope = CurrentRequestLifetimeScope};

                return attribute;
            }
        }
    }
}