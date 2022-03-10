using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.DmsIntegration.Component.iManage;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    public interface ISettingTester
    {
        Task<IEnumerable<ConnectionResponseModel>> TestConnections(ConnectionTestRequestModel settings);
    }

    public class SettingTester : ISettingTester
    {
        readonly ICredentialsResolver _credentialsResolver;
        readonly IDmsEventCapture _dmsEventCapture;
        readonly IDmsEventSink _dmsEventSink;
        readonly ILogger<SettingTestController> _logger;
        readonly IWorkSiteManagerFactory _workSiteManagerFactory;

        public SettingTester(IWorkSiteManagerFactory workSiteManagerFactory, ICredentialsResolver credentialsResolver, IDmsEventSink dmsEventSink, ILogger<SettingTestController> logger, IDmsEventCapture dmsEventCapture)
        {
            _workSiteManagerFactory = workSiteManagerFactory;
            _credentialsResolver = credentialsResolver;
            _dmsEventSink = dmsEventSink;
            _logger = logger;
            _dmsEventCapture = dmsEventCapture;
        }

        public async Task<IEnumerable<ConnectionResponseModel>> TestConnections(ConnectionTestRequestModel settings)
        {
            var tasks = settings.Settings
                                .Select(_ => CreateTesterTask(_, settings.UserName, settings.Password))
                                .ToArray();

            await Task.WhenAll(tasks);

            return tasks.Select(t => t.Result)
                        .ToArray();
        }

        async Task<ConnectionResponseModel> CreateTesterTask(IManageSettings.SiteDatabaseSettings setting, string username, string password)
        {
            var credentials = await _credentialsResolver.Resolve(setting);
            var manager = _workSiteManagerFactory.GetWorkSiteManager(setting);
            var success = false;
            if (setting.LoginType == IManageSettings.LoginTypes.OAuth)
            {
                return new ConnectionResponseModel {Success = true};
            }

            try
            {
                success = await manager.Connect(setting, username ?? credentials.UserName, password ?? credentials.Password);
            }
            catch (Exception e)
            {
                _dmsEventCapture.Capture(
                                         new DocumentManagementEvent
                                         {
                                             Key = KnownDocumentManagementEvents.ServerNotFound,
                                             Status = Status.Error
                                         });
                _logger.Exception(e);
            }

            return new ConnectionResponseModel
            {
                Success = success,
                ErrorMessages = GetErrors()
            };
        }

        IEnumerable<string> GetErrors()
        {
            var errorEventsRequired = new[]
            {
                KnownDocumentManagementEvents.MissingLoginPreference,
                KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences,
                KnownDocumentManagementEvents.FailedConnection,
                KnownDocumentManagementEvents.IncompleteConfiguration,
                KnownDocumentManagementEvents.FailedConnectionIfImpersonationAuthenticationFailure,
                KnownDocumentManagementEvents.ServerNotFound
            };

            return _dmsEventSink.GetEvents(Status.Error, errorEventsRequired).ToList().Select(_ => _.Key).Distinct();
        }
    }

    public class ConnectionTestRequestModel
    {
        public IEnumerable<IManageSettings.SiteDatabaseSettings> Settings { get; set; }
        public string UserName { get; set; }
        public string Password { get; set; }
    }

    public class ConnectionResponseModel
    {
        public bool Success { get; set; }
        public IEnumerable<string> ErrorMessages { get; set; } = new string[0];
    }
}