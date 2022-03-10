using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Exceptions;
using Inprotech.Integration.Properties;
using InprotechKaizen.Model.Components.Integration.ReportingServices;
using InprotechKaizen.Model.Components.Reporting;

namespace Inprotech.Integration.Reports
{
    public interface IReportClient
    {
        Task<bool> TestConnectionAsync(ReportingServicesSetting setting);

        Task<ContentResult> GetReportAsync(ReportDefinition reportDefinition, Stream output);
    }

    public class ReportClient : IReportClient
    {
        static readonly ConcurrentDictionary<string, (string EffectiveReportPath, DateTime lastCheckedUTC)> ReportPathCache = new(StringComparer.InvariantCultureIgnoreCase);
        HttpClient _reportClient;
        readonly Func<DateTime> _systemClock;
        readonly IReportingServicesSettingsResolver _settingsResolver;
        readonly IBackgroundProcessLogger<ReportClient> _log;
        readonly IReportClientProvider _reportClientProvider;
        ReportingServicesSetting _settings;

        public ReportClient(
            Func<DateTime> systemClock,
            IReportingServicesSettingsResolver settingsResolver, IBackgroundProcessLogger<ReportClient> log, IReportClientProvider reportClientProvider)
        {
            _systemClock = systemClock;
            _settingsResolver = settingsResolver;
            _log = log;
            _reportClientProvider = reportClientProvider;
        }

        public async Task<bool> TestConnectionAsync(ReportingServicesSetting settings)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            var url = $"{settings.ReportServerBaseUrl}?/{settings.RootFolder}/billing/standard&rs:Command=GetChildren";

            var httpClient = new HttpClient(
                                            new HttpClientHandler
                                            {
                                                Credentials = settings.Security.IsEmpty()
                                                    ? CredentialCache.DefaultNetworkCredentials
                                                    : new NetworkCredential(
                                                                            settings.Security.Username,
                                                                            settings.Security.Password,
                                                                            settings.Security.Domain)
                                            });

            try
            {
                var response = await httpClient.GetAsync(url);
                var content = await response.Content.ReadAsStringAsync();
                return content.Contains("Microsoft SQL Server Reporting Services");
            }
            catch (Exception ex)
            {
                var credentialType = settings.Security.IsEmpty() ? "Default Network Credentials" : "supplied credentials";

                _log.Trace($"Test Connection conducted using {credentialType} failed: {ex.Message}");

                return false;
            }
        }

        public async Task<ContentResult> GetReportAsync(ReportDefinition reportDefinition, Stream output)
        {
            if (reportDefinition == null) throw new ArgumentNullException(nameof(reportDefinition));
            if (output == null) throw new ArgumentNullException(nameof(output));

            var result = new ContentResult();
            var hasTailoredReport = false;
            try
            {
                var expectedContentType = KnownReportComponents.Map[reportDefinition.ReportExportFormat].ContentType;

                var settings = await LoadReportSettings();
                var rootFolder = settings.RootFolder;
                
                reportDefinition.Parameters.Add("rs:Command", "Render");
                reportDefinition.Parameters.Add("rc:LinkTarget", "main");
                reportDefinition.Parameters.Add("rs:Format", reportDefinition.ReportExportFormat.ToString());

                var reportPath = $"/{rootFolder}/{reportDefinition.ReportPath.TrimStart('/').TrimEnd('/').ToLower()}";

                byte[] reportContent = null;

                if (reportPath.Contains("/standard/"))
                {
                    var effectiveReportPath = reportPath;
                    if (ReportPathCache.TryGetValue(reportPath, out var cachedReportPath))
                    {
                        if (_systemClock().ToUniversalTime() - cachedReportPath.lastCheckedUTC <= TimeSpan.FromHours(4))
                        {
                            effectiveReportPath = cachedReportPath.EffectiveReportPath;
                            hasTailoredReport = !string.Equals(effectiveReportPath, reportPath, StringComparison.InvariantCultureIgnoreCase);
                        }
                    }
                    else
                    {
                        hasTailoredReport = true;
                    }

                    if (hasTailoredReport)
                    {
                        var tailoredReport = reportPath.Replace("/standard/", "/tailored/");
                        _log.Trace($"Rendering report {tailoredReport}");

                        try
                        {
                            reportContent = await GetReportContentAsync(tailoredReport, reportDefinition.Parameters, expectedContentType);
                        }
                        catch (ReportNotFoundException)
                        {
                            _log.Trace($"Report not found at: {tailoredReport}");
                            hasTailoredReport = false;
                        }

                        if (reportContent != null)
                        {
                            hasTailoredReport = true;
                            effectiveReportPath = tailoredReport;
                            ReportPathCache.AddOrUpdate(reportPath, 
                                                        x => (effectiveReportPath, _systemClock().ToUniversalTime()),
                                                        (k,v) => (effectiveReportPath, _systemClock().ToUniversalTime()));
                        }
                    }
                }

                if (!hasTailoredReport)
                {
                    _log.Trace($"Rendering report {reportPath}");
                    reportContent = await GetReportContentAsync(reportPath, reportDefinition.Parameters, expectedContentType);
                    ReportPathCache.AddOrUpdate(reportPath, 
                                                x => (reportPath, _systemClock().ToUniversalTime()),
                                                (k,v) => (reportPath, _systemClock().ToUniversalTime()));
                }

                if (reportContent != null)
                {
                    await output.WriteAsync(reportContent, 0, reportContent.Length);
                    _log.Trace($"Report {reportPath} saved into memory stream - {reportContent.Length}");
                }
            }
            catch (Exception ex)
            {
                _log.Exception(ex);
                result.Exception = ex;
            }

            return result;
        }

        async Task<byte[]> GetReportContentAsync(string reportPath, Dictionary<string, string> parameter, string expectedContentType)
        {
            if (string.IsNullOrEmpty(reportPath)) return null;

            var settings = await LoadReportSettings();

            var url = settings.ReportServerBaseUrl + "?" + WebUtility.UrlEncode(reportPath);
            
            _reportClient ??= await _reportClientProvider.GetClient();

            using var postContent = new FormUrlEncodedContent(parameter);
            using var response = await _reportClient.PostAsync(url, postContent);
            if (!response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();
                if (content.Contains("rsItemNotFound"))
                    throw new ReportNotFoundException();

                _log.Debug(content);
                throw new ReportServerInternalServerErrorException(reportPath, content);
            }

            var hasExpectedContentType = response.Content != null
                                         && response.Content.Headers.ContentType.MediaType
                                                    .Equals(expectedContentType, StringComparison.InvariantCultureIgnoreCase);

            if (!hasExpectedContentType)
            {
                throw new ReportServerInternalServerErrorException(reportPath, Alerts.SsrsReturnsUnExpectedContentType);
            }

            response.EnsureSuccessStatusCode();

            using (var content = response.Content)
            {
                return await content.ReadAsByteArrayAsync();
            }
        }

        async Task<ReportingServicesSetting> LoadReportSettings()
        {
            var settings = await _settingsResolver.Resolve();

            if (settings.IsValid())
            {
                _settings = settings;
                return _settings;
            }

            throw new ReportingServicesConfigurationException("Reporting Services Settings unavailable or has not been configured.");
        }
    }

    public class ContentResult
    {
        public bool HasError => Exception != null;
        public Exception Exception { get; set; }
    }
}