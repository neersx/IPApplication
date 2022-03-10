using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Forms;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Utilities;
using Inprotech.Setup.UI;
using Nito.AsyncEx;
using Screen = Caliburn.Micro.Screen;

namespace Inprotech.Setup.Pages
{
    public class BasicSettingViewModel : Screen, INotifyDataErrorInfo, ISettingsViewModel
    {
        const string StorageLocationKey = "StorageLocation";
        const string BrowseDescription = "Folder location for storing external Inprotech files.";

        readonly FolderValidationInput _input = new FolderValidationInput();
        readonly IMessageBox _messageBox;
        readonly IAppConfigReader _defaultAppConfigReader;
        readonly IPorts _ports;
        readonly string _sourceLocation = @"C:\Inprotech\Storage\";

        readonly Dictionary<string, ICollection<string>> _validationErrors = new Dictionary<string, ICollection<string>>();
        readonly IValidationService _validationService;

        string _storageLocation = @"C:\Inprotech\Storage";
        Uri _inprotechIntegrationServerUrl;
        Uri _localInprotechIntegrationServerUrl;
        Uri _remoteInprotechIntegrationServerUrl;

        string IntegrationServerHostingPath;
        string StorageServiceHostingPath;
        
        public BasicSettingViewModel(IValidationService validationService, IPorts ports, IMessageBox messageBox, IWebAppInfoManager manager, IAppConfigReader defaultAppConfigReader)
        {
            _validationService = validationService;
            _ports = ports;
            _messageBox = messageBox;
            _defaultAppConfigReader = defaultAppConfigReader;

            InprotechServerUrls = new List<Uri>();

            if (!string.IsNullOrWhiteSpace(Context.StorageLocation))
            {
                _sourceLocation = $@"{Context.StorageLocation}\";
                StorageLocation = Context.StorageLocation;
            }

            Instances = new InstanceServiceStatus[0];
            InstanceName = Context.SelectedWebApp?.InstanceName;
            if (string.IsNullOrWhiteSpace(InstanceName))
            {
                var iisPath = Context.ResolvedIisApp.VirtualPath;
                InstanceName = manager.GetNewInstanceName(iisPath);
            }

            InprotechServerUrls.AddRange(Context.ResolvedIisApp.BindingUrls
                                                .Split(',')
                                                .Select(CreateAppsUriFromBindingUrls));

            _localInprotechIntegrationServerUrl = CreateIntegrationServerUriFromBindingUrls();
            _remoteInprotechIntegrationServerUrl = Context.RemoteIntegrationServerUrl;

            _inprotechIntegrationServerUrl = _remoteInprotechIntegrationServerUrl ?? _localInprotechIntegrationServerUrl;

            FindStorageServiceHostingPath();

            NotifyTaskCompletion.Create(PopulateInstances(this));
        }

        static Uri CreateAppsUriFromBindingUrls(string url)
        {
            return new Uri(url.Replace("*", "localhost").TrimEnd('/') + Context.ResolvedIisApp.VirtualPath + "/apps");
        }

        Uri CreateIntegrationServerUriFromBindingUrls()
        {
            var settings = Context.SelectedWebApp == null
                ? _defaultAppConfigReader.ReadInprotechIntegrationAppSettings()
                : Context.SelectedWebApp.ComponentConfigurations.AppSettings("Inprotech Integration Server");

            var host = settings["Host"] == "*" ? "localhost" : settings["Host"];
            IntegrationServerHostingPath = settings["Path"];
            var port = string.IsNullOrWhiteSpace(Context.IntegrationServerPort)
                    ? _ports.Allocate()
                    : int.Parse(Context.IntegrationServerPort);

            return new Uri($"http://{host}:{port}/{IntegrationServerHostingPath}-{InstanceName.Replace($"-{Environment.MachineName}".ToLower(), string.Empty)}");
        }

        void FindStorageServiceHostingPath()
        {
            var settings = Context.SelectedWebApp == null
                ? _defaultAppConfigReader.ReadInprotechStorageServiceAppSettings()
                : Context.SelectedWebApp.ComponentConfigurations.AppSettings("Inprotech Storage Service");

            if (Context.SelectedWebApp != null && !settings.Any() && Context.RunMode == SetupRunMode.Upgrade)
                settings = _defaultAppConfigReader.ReadInprotechStorageServiceAppSettings();

            StorageServiceHostingPath = settings.ContainsKey("Path") ? settings["Path"] : null;
        }

        public string InstanceName { get; }

        public Uri InprotechIntegrationServerUrl
        {
            get => _inprotechIntegrationServerUrl;
            set
            {
                _inprotechIntegrationServerUrl = value;
                NotifyOfPropertyChange(() => InprotechIntegrationServerUrl);
                NotifyOfPropertyChange(() => InprotechStorageServiceUrl);
            }
        }

        public Uri InprotechStorageServiceUrl => string.IsNullOrEmpty(StorageServiceHostingPath) ? null : new Uri(InprotechIntegrationServerUrl.ToString().Replace(IntegrationServerHostingPath, StorageServiceHostingPath));

        public bool IsStorageServiceConfigurable => !string.IsNullOrEmpty(StorageServiceHostingPath);

        public List<Uri> InprotechServerUrls { get; }

        public bool IsMultiNode => Instances.Any();

        public string StorageLocation
        {
            get => _storageLocation;
            set
            {
                _storageLocation = value;
                SetErrors(StorageLocationKey, null);
                NotifyOfPropertyChange(() => StorageLocation);
            }
        }

        public bool CanEditCookieConsentHook { get; private set; }

        public IEnumerable<InstanceServiceStatus> Instances { get; private set; }

        IEnumerable<InstanceServiceStatus> _integrationServerInstances;

        public void SetInstanceDetails(InstanceDetails instanceDetails)
        {
            Instances = instanceDetails.InprotechServer.Where(_ => _.Name != InstanceName);
            _integrationServerInstances = instanceDetails.IntegrationServer.Where(_ => _.Name != InstanceName);
            NotifyOfPropertyChange(() => Instances);
            NotifyOfPropertyChange(() => IsMultiNode);
        }

        public void SetSetupSettings(Dictionary<string, string> settings)
        {

        }

        public event EventHandler<DataErrorsChangedEventArgs> ErrorsChanged;

        bool INotifyDataErrorInfo.HasErrors => _validationErrors.Count > 0;

        IEnumerable INotifyDataErrorInfo.GetErrors(string propertyName)
        {
            if (string.IsNullOrEmpty(propertyName)
                || !_validationErrors.ContainsKey(propertyName))
            {
                return null;
            }

            return _validationErrors[propertyName];
        }

        static async Task PopulateInstances(ISettingsViewModel viewModel)
        {
            var connectionString = Context.ResolvedIisApp.WebConfig.InprotechConnectionString;

            var configManager = new InprotechServerPersistingConfigManager();

            viewModel.SetInstanceDetails(await configManager.GetPersistedInstanceDetails(connectionString));
        }

        public void Browse()
        {
            var dialog = new FolderBrowserDialog
            {
                Description = BrowseDescription,
                SelectedPath = StorageLocation
            };

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                StorageLocation = dialog.SelectedPath;
            }
        }

        public void ConfigureIntegrationServer()
        {
            var viewModel = new IntegrationServerHttpIdentityViewModel(_ports, _localInprotechIntegrationServerUrl, _remoteInprotechIntegrationServerUrl, _integrationServerInstances);
            var dialog = new IntegrationServerHttpIdentity(viewModel);
            if (dialog.ShowDialog() == true)
            {
                _localInprotechIntegrationServerUrl = viewModel.LocalIntegrationServerUrl;
                _remoteInprotechIntegrationServerUrl = viewModel.RemoteIntegrationServerUrl;

                InprotechIntegrationServerUrl = viewModel.LocalOrRemote == LocalOrRemoteIntegrationServer.Local
                    ? _localInprotechIntegrationServerUrl
                    : _remoteInprotechIntegrationServerUrl;
            }
        }

        void RaiseErrorsChanged(string propertyName)
        {
            ErrorsChanged?.Invoke(this, new DataErrorsChangedEventArgs(propertyName));
        }

        bool ShouldUseSharedPath()
        {
            return Instances.Any() && _remoteInprotechIntegrationServerUrl == null;
        }

        async Task Validate()
        {
            ICollection<string> validationErrors = null;
            await Task.Run(() => _validationService.ValidateFolder(
                                                                   new FolderValidationInput
                                                                   {
                                                                       CurrentValue = StorageLocation,
                                                                       OriginalValue = _sourceLocation,
                                                                       ShouldUseSharedPath = ShouldUseSharedPath()
                                                                   }, out validationErrors));

            switch (validationErrors.FirstOrDefault())
            {
                case FolderValidationErrors.DirectoryDoesNotExist:
                    validationErrors = PromptCreateDirectory(validationErrors);
                    SetErrors(StorageLocationKey, validationErrors);
                    return;

                case FolderValidationErrors.PathShouldBeAccesssibleToAllNodes:
                    validationErrors = PromptIgnoreMultinodeRequirement(validationErrors);
                    SetErrors(StorageLocationKey, validationErrors);
                    return;

                default:
                    SetErrors(StorageLocationKey, validationErrors);
                    break;
            }
        }

        ICollection<string> PromptIgnoreMultinodeRequirement(ICollection<string> validationErrors)
        {
            if (_input.CurrentValue == StorageLocation && _input.OriginalValue == _sourceLocation)
            {
                return null; // already ignored once;
            }

            var message = "Multi-node installation requires the Storage Location to be accessible by all nodes. The specified path does not currently meet this requirement.";
            message += Environment.NewLine;
            message += "Do you want to continue anyway?";

            var ignore = _messageBox.Confirm(message, "Network Location Required");
            if (ignore == MessageBoxResult.Yes)
            {
                _input.CurrentValue = StorageLocation;
                _input.OriginalValue = _sourceLocation;
                validationErrors = null;
            }

            return validationErrors;
        }

        ICollection<string> PromptCreateDirectory(ICollection<string> validationErrors)
        {
            var create = _messageBox.Confirm("The directory does not exist, do you want to create it?",
                                             "Create Directory");

            if (create == MessageBoxResult.Yes)
            {
                try
                {
                    Directory.CreateDirectory(StorageLocation);
                    validationErrors = null;
                }
                catch
                {
                    validationErrors = new[] { "Unable to create directory" };
                }
            }

            return validationErrors;
        }

        void SetErrors(string propertyName, ICollection<string> errors)
        {
            if (errors == null || errors.Count == 0)
            {
                if (_validationErrors.ContainsKey(propertyName))
                {
                    _validationErrors.Remove(propertyName);
                    RaiseErrorsChanged(propertyName);
                }
            }
            else
            {
                _validationErrors[propertyName] = errors;
                RaiseErrorsChanged(propertyName);
            }
        }

        public override async void CanClose(Action<bool> callback)
        {
            await Validate();
            if (((INotifyDataErrorInfo)this).HasErrors)
            {
                callback(false);
                return;
            }

            callback(true);
        }

        protected override void OnDeactivate(bool close)
        {
            base.OnDeactivate(close);

            Context.StorageLocation = StorageLocation;
            Context.IntegrationServerPort = InprotechIntegrationServerUrl.Port.ToString();
            Context.RemoteIntegrationServerUrl = _remoteInprotechIntegrationServerUrl;
            Context.RemoteStorageServiceUrl = Context.RemoteIntegrationServerUrl == null ? null : InprotechStorageServiceUrl;
        }
    }

    public static class InstancesDataProvider
    {
        public static async Task<IEnumerable<InstanceServiceStatus>> GetAsync(string connectionString, string instanceName)
        {
            var instanceDetails = await new InprotechServerPersistingConfigManager().GetPersistedInstanceDetails(connectionString);
            return instanceDetails.InprotechServer.Where(_ => _.Name != instanceName);
        }
    }
}