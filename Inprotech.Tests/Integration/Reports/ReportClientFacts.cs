using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Integration.Reports;
using InprotechKaizen.Model.Components.Integration.ReportingServices;
using InprotechKaizen.Model.Components.Reporting;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Reports
{
    public class ReportClientFacts : FactBase
    {
        readonly IReportingServicesSettingsResolver _reportingServicesSettingsResolver = Substitute.For<IReportingServicesSettingsResolver>();
        readonly IBackgroundProcessLogger<ReportClient> _log = Substitute.For<IBackgroundProcessLogger<ReportClient>>();
        readonly IReportClientProvider _reportClientProvider = Substitute.For<IReportClientProvider>();

        ReportClient GetSubject()
        {
            _reportingServicesSettingsResolver.Resolve().Returns(new ReportingServicesSetting
            {
                Timeout = 10,
                RootFolder = "inpro",
                MessageSize = 105,
                ReportServerBaseUrl = "http://localhost/reportserver",
                Security = new SecurityElement
                {
                    Password = "password",
                    Username = "username",
                    Domain = "int"
                }
            });
            return new ReportClient(Fixture.TodayUtc, _reportingServicesSettingsResolver, _log, _reportClientProvider);
        }

        [Fact]
        public async Task GetReportAsyncResponseShouldBeOk()
        {
       
            var httpClient = new HttpClient(new HttpMessageHandlerStub(async (request, cancellationToken) =>
            {
                var responseMessage = new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new ByteArrayContent(new byte[500]),

                };

                responseMessage.Content.Headers.Add("Content-Type","application/pdf");
                return await Task.FromResult(responseMessage);
            }));
            _reportClientProvider.GetClient().Returns(httpClient);

            var sm = new MemoryStream();
            var sb = GetSubject();
            var result = await sb.GetReportAsync(new ReportDefinition
            {
                ReportPath = "/standard/billingWorksheet/",
                ReportExportFormat = ReportExportFormat.Pdf,
                Parameters = new Dictionary<string, string>()
            }, sm);

            Assert.False(result.HasError);
            Assert.Equal(sm.Length, 500);
        }

        [Fact]
        public async Task GetReportAsyncShouldExpectException()
        {
            var httpClient = new HttpClient(new HttpMessageHandlerStub(async (request, cancellationToken) =>
            {
                var responseMessage = new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new ByteArrayContent(new byte[500])
                };

                return await Task.FromResult(responseMessage);
            }));
            _reportClientProvider.GetClient().Returns(httpClient);

            var sm = new MemoryStream();
            var sb = GetSubject();
            var result = await sb.GetReportAsync(new ReportDefinition
            {
                ReportPath = "/standard/billing/",
                ReportExportFormat = ReportExportFormat.Pdf,
                Parameters = new Dictionary<string, string>()
            }, sm);

            Assert.True(result.HasError);
            Assert.NotEqual(sm.Length, 500);
        }

        [Fact]
        public async Task TestConnectionAsyncShouldRaiseException()
        {
            var sb = GetSubject();
            await Assert.ThrowsAsync<ArgumentNullException>(() => sb.TestConnectionAsync(null));
        }
    }

    public class HttpMessageHandlerStub : HttpMessageHandler
    {
        readonly Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> _sendAsync;

        public HttpMessageHandlerStub(Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> sendAsync)
        {
            _sendAsync = sendAsync;
        }

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (request.RequestUri.ToString().Equals("http://localhost/reportserver?%2Finpro%2Fstandard%2Fbillingworksheet"))
            {
                return await _sendAsync(request, cancellationToken);
            }

            return new HttpResponseMessage(HttpStatusCode.BadRequest)
            {
                Content = new StringContent("rsItemNotFound")
            };
        }
    }
}