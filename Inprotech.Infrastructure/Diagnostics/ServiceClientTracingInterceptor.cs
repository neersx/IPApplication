using System;
using System.Collections.Generic;
using System.Net.Http;
using Inprotech.Contracts;
using Microsoft.Rest;

namespace Inprotech.Infrastructure.Diagnostics
{
    public class ServiceClientTracingInterceptor : IServiceClientTracingInterceptor
    {
        readonly IBackgroundProcessLogger<ServiceClientTracingInterceptor> _logger;

        public ServiceClientTracingInterceptor(IBackgroundProcessLogger<ServiceClientTracingInterceptor> logger)
        {
            _logger = logger;
        }

        public void Information(string message)
        {
            _logger.Information(message);
        }

        public void TraceError(string invocationId, Exception exception)
        {
            _logger.Exception(exception, $"ERROR:InvocationId: {invocationId}");
        }

        public void ReceiveResponse(string invocationId, HttpResponseMessage response)
        {
            var requestAsString = response == null ? string.Empty : response.AsFormattedString();
            _logger.Trace($"RECEIVE:InvocationId: {invocationId}{Environment.NewLine}{requestAsString}");
        }

        public void SendRequest(string invocationId, HttpRequestMessage request)
        {
            var requestAsString = request == null ? string.Empty : request.AsFormattedString();
            _logger.Trace($"SEND:InvocationId: {invocationId}{Environment.NewLine}{requestAsString}");
        }

        public void Configuration(string source, string name, string value)
        {
            _logger.Trace($"CONFIG: {source} {name}={value}");
        }

        public void EnterMethod(string invocationId, object instance, string method, IDictionary<string, object> parameters)
        {
            _logger.Trace($"ENTER:InvocationId: {invocationId}{Environment.NewLine}Instance: {instance}{Environment.NewLine}Method: {method}{Environment.NewLine}Parameters: {parameters.AsFormattedString()}");
        }

        public void ExitMethod(string invocationId, object returnValue)
        {
            var returnValueAsString = returnValue == null ? string.Empty : returnValue.ToString();
            _logger.Trace($"EXIT:InvocationId: {invocationId}{Environment.NewLine}{returnValueAsString}");
        }
    }
}