using System;
using System.Net.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Inprotech.Tests.Web.Builders;
using NSubstitute;

namespace Inprotech.Tests.Infrastructure.Web
{
    public class HttpActionExecutedContextBuilder : IBuilder<HttpActionExecutedContext>
    {
        readonly HttpRequestMessage _request;
        Exception _exception;
        HttpResponseMessage _response;

        public HttpActionExecutedContextBuilder(HttpRequestMessage request)
        {
            _request = request;
        }

        public HttpActionExecutedContext Build()
        {
            return new HttpActionExecutedContext(
                                                 new HttpActionContext(
                                                                       new HttpControllerContext {Request = _request},
                                                                       Substitute.For<HttpActionDescriptor>()),
                                                 null)
            {
                Response = _response,
                Exception = _exception
            };
        }

        public HttpActionExecutedContextBuilder WithResponse(HttpResponseMessage response)
        {
            _response = response;
            return this;
        }

        public HttpActionExecutedContextBuilder WithException(Exception exception)
        {
            _exception = exception;
            return this;
        }
    }
}