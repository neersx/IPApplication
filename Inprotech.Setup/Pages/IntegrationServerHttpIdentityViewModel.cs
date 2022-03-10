using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Caliburn.Micro;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Annotations;
using Inprotech.Setup.Core.Utilities;
using NLog;
using LogManager = NLog.LogManager;

namespace Inprotech.Setup.Pages
{
    public enum LocalOrRemoteIntegrationServer
    {
        NotSet,
        Local,
        Remote
    }

    public class IntegrationServerHttpIdentityViewModel : Screen
    {
        static readonly Logger Logger = LogManager.GetCurrentClassLogger();

        readonly IPorts _ports;
        IntegrationServerConfiguration _integrationServerConfiguration;
        LocalOrRemoteIntegrationServer _localOrRemote;

        int _port;

        public IntegrationServerHttpIdentityViewModel([NotNull] IPorts ports, [NotNull] Uri currentLocalUrl, Uri remoteIntegrationServerUrl, [NotNull] IEnumerable<InstanceServiceStatus> instances)
        {
            if (currentLocalUrl == null) throw new ArgumentNullException(nameof(currentLocalUrl));
            if (instances == null) throw new ArgumentException(nameof(instances));
            _ports = ports ?? throw new ArgumentNullException(nameof(ports));

            _port = currentLocalUrl.Port;

            LocalIntegrationServerUrl = currentLocalUrl;

            RemoteIntegrationServerUrl = remoteIntegrationServerUrl;

            Instances = new ObservableCollection<IntegrationServerConfiguration>(instances
                                                                                 .Select(_ => new IntegrationServerConfiguration(_))
                                                                                 .Where(_ => !string.IsNullOrWhiteSpace(_.OriginalBindingUrl)));

            LocalOrRemote = TryPreselectRemoteInstance()
                ? LocalOrRemoteIntegrationServer.Remote
                : LocalOrRemoteIntegrationServer.Local;
        }

        public bool IsEntryAllowed => SelectedIntegrationServerConfiguration != null;

        public int Port
        {
            get => _port;
            set
            {
                _port = value;
                var uriBuilder = new UriBuilder(LocalIntegrationServerUrl) {Port = _port};
                LocalIntegrationServerUrl = uriBuilder.Uri;

                NotifyOfPropertyChange(() => Port);
                NotifyOfPropertyChange(() => LocalIntegrationServerUrl);
            }
        }

        public LocalOrRemoteIntegrationServer LocalOrRemote
        {
            get => _localOrRemote;
            set
            {
                _localOrRemote = value;

                if (_localOrRemote == LocalOrRemoteIntegrationServer.Remote)
                {
                    TryPreselectRemoteInstance(true);
                }

                NotifyOfPropertyChange(() => LocalOrRemote);
                NotifyOfPropertyChange(() => IsBusy);
            }
        }

        public bool IsBusy => (SelectedIntegrationServerConfiguration?.IsBusy).GetValueOrDefault();

        public Uri LocalIntegrationServerUrl { get; set; }

        public Uri RemoteIntegrationServerUrl { get; set; }

        public bool IsMultiNode => Instances.Any();

        public IntegrationServerConfiguration SelectedIntegrationServerConfiguration
        {
            get => _integrationServerConfiguration;
            set
            {
                _integrationServerConfiguration = value;
                NotifyOfPropertyChange(() => SelectedIntegrationServerConfiguration);
                NotifyOfPropertyChange(() => IsBusy);
                NotifyOfPropertyChange(() => IsEntryAllowed);
            }
        }

        public ObservableCollection<IntegrationServerConfiguration> Instances { get; }

        bool TryPreselectRemoteInstance(bool selectFirstIfNotFound = false)
        {
            if (RemoteIntegrationServerUrl != null)
            {
                var matched = Instances.SingleOrDefault(_ => RemoteIntegrationServerUrl.ToString().TrimEnd('/').EndsWith(_.LastPath ?? string.Empty));
                if (matched != null)
                {
                    SelectedIntegrationServerConfiguration = matched;
                    SelectedIntegrationServerConfiguration.EnteredUrl = RemoteIntegrationServerUrl.ToString();

                    return true;
                }
            }

            if (selectFirstIfNotFound && Instances.Any())
            {
                SelectedIntegrationServerConfiguration = Instances.First();
                return true;
            }

            return false;
        }

        public void NextAvailable()
        {
            Port = _ports.Allocate();
        }

        public async Task Validate()
        {
            if (SelectedIntegrationServerConfiguration == null) return;

            var config = SelectedIntegrationServerConfiguration;

            if (config.IsBusy) return;

            config.Error = null;
            config.IsBusy = false;
            config.IsUrlAccessible = false;

            if (string.IsNullOrWhiteSpace(config.EnteredUrl))
            {
                config.Error = "This field is mandatory";
                return;
            }

            if (!config.EnteredUrl.EndsWith(config.LastPath))
            {
                config.Error = $"The last part of the path should remain as '{config.LastPath}'";
                return;
            }

            if (Uri.TryCreate(config.EnteredUrl.TrimEnd('/') + "/api/integrationserver/status", UriKind.Absolute, out var createdUri))
            {
                SetIsBusy(config, true);

                using (var client = new WebClient())
                {
                    try
                    {
                        Logger.Info($"Testing connectivity: {createdUri}");

                        var result = await client.DownloadStringTaskAsync(createdUri);

                        Logger.Info($"Connectivity established: {createdUri} ({result})");
                        config.IsUrlAccessible = true;
                        SetIsBusy(config, false);
                    }
                    catch (Exception ex)
                    {
                        Logger.Error(ex, $"Test connectivity with {createdUri} failed");
                        config.Error = ex.Message;
                        config.IsUrlAccessible = false;
                        SetIsBusy(config, false);
                    }
                }
            }
            else
            {
                config.Error = "This is not a valid URL";
                config.IsUrlAccessible = false;
            }
        }

        public async Task<bool> CanProceed()
        {
            var canProceed = false;

            switch (LocalOrRemote)
            {
                case LocalOrRemoteIntegrationServer.Local:
                    RemoteIntegrationServerUrl = null;
                    canProceed = true;
                    break;

                case LocalOrRemoteIntegrationServer.Remote:
                    if (Uri.TryCreate(SelectedIntegrationServerConfiguration.EnteredUrl, UriKind.Absolute, out var createdUri))
                    {
                        RemoteIntegrationServerUrl = createdUri;
                        canProceed = true;
                    }
                    else
                    {
                        await Validate();
                    }

                    break;
            }

            return canProceed;
        }

        void SetIsBusy(IntegrationServerConfiguration config, bool isBusy)
        {
            if (config != null)
            {
                config.IsBusy = isBusy;
            }

            NotifyOfPropertyChange(() => IsBusy);
        }
    }

    public class IntegrationServerConfiguration : InstanceServiceStatus, INotifyDataErrorInfo
    {
        readonly Dictionary<string, ICollection<string>> _validationErrors = new Dictionary<string, ICollection<string>>();

        public IntegrationServerConfiguration(InstanceServiceStatus originalInstanceServiceStatus)
        {
            Name = originalInstanceServiceStatus.Name;
            MachineName = originalInstanceServiceStatus.MachineName;
            Version = originalInstanceServiceStatus.Version;
            Utc = originalInstanceServiceStatus.Utc;
            Status = originalInstanceServiceStatus.Status;
            Endpoints = originalInstanceServiceStatus.Endpoints;
            EnteredUrl = OriginalBindingUrl;

            if (!string.IsNullOrWhiteSpace(OriginalBindingUrl) && Uri.TryCreate(OriginalBindingUrl, UriKind.Absolute, out var result))
            {
                var r = result.ToString();
                LastPath = r.Substring(r.LastIndexOf('/'));
            }
        }

        public string OriginalBindingUrl
        {
            get
            {
                var endpoint = Endpoints.FirstOrDefault();

                return endpoint == null
                    ? null
                    : endpoint.Replace("*", MachineName).TrimEnd('/');
            }
        }

        public string LastPath { get; }

        public string EnteredUrl { get; set; }

        public bool IsUrlAccessible { get; set; }

        public bool IsBusy { get; set; }

        public string Error
        {
            get => _validationErrors.TryGetValue(nameof(EnteredUrl), out var errors)
                ? string.Join(", ", errors)
                : null;
            set
            {
                if (string.IsNullOrWhiteSpace(value))
                {
                    if (_validationErrors.ContainsKey(nameof(EnteredUrl)))
                    {
                        _validationErrors.Remove(nameof(EnteredUrl));
                        RaiseErrorsChanged(nameof(EnteredUrl));
                    }
                }
                else
                {
                    _validationErrors[nameof(EnteredUrl)] = new[] {value};
                    RaiseErrorsChanged(nameof(EnteredUrl));
                }
            }
        }

        public bool HasErrors => _validationErrors.Any();

        public event EventHandler<DataErrorsChangedEventArgs> ErrorsChanged;

        public IEnumerable GetErrors(string propertyName)
        {
            if (string.IsNullOrEmpty(propertyName)
                || !_validationErrors.ContainsKey(propertyName))
            {
                return null;
            }

            return _validationErrors[propertyName];
        }

        void RaiseErrorsChanged(string propertyName)
        {
            ErrorsChanged?.Invoke(this, new DataErrorsChangedEventArgs(propertyName));
        }
    }
}