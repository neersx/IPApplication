using System;
using System.Collections.Generic;
using System.Linq;
using Caliburn.Micro;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Pages
{
    public class WebAppConfigurationViewModel : Screen
    {
        readonly InstanceComponentConfiguration _configuration;
        bool _displayConnectionString;

        public WebAppConfigurationViewModel(InstanceComponentConfiguration configuration)
        {
            _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));

            var displayable1 = _configuration.Configuration;

            var displayable2 = displayable1.ContainsKey("Hide AppSettings") ? new Dictionary<string, string>() : _configuration.AppSettings;

            Settings = new BindableCollection<KeyValuePair<string, string>>(HideEncrypted(displayable1).Concat(HideEncrypted(displayable2)));
        }

        public string Name => _configuration.Name;

        public BindableCollection<KeyValuePair<string, string>> Settings { get; }

        public bool DisplayConnectionString
        {
            get => _displayConnectionString;
            set { _displayConnectionString = value; NotifyOfPropertyChange(() => DisplayConnectionString); }
        }

        static IDictionary<string, string> HideEncrypted(IDictionary<string, string> appSettings)
        {
            return appSettings.Where(Show).ToDictionary(k => k.Key, v => v.Value);

            bool Show(KeyValuePair<string, string> item)
            {
                if (Constants.ExcludedEncryptedSettings.Contains(item.Key))
                    return false;
                if (Constants.ExcludedEncryptedSettings.FirstOrDefault(_ => _.EndsWith("*") && item.Key.StartsWith(_.Replace("*", string.Empty))) != null)
                    return false;
                return true;
            }
        }
    }

    public static class BindableCollectionWebAppConfigurationViewModelExt
    {
        public static BindableCollection<KeyValuePair<string, string>> AppSettings(this BindableCollection<WebAppConfigurationViewModel> collection, string server)
        {
            return collection.SingleOrDefault(_ => _.Name == server)?.Settings;
        }
    }

    public static class InstanceComponentConfigurationEnumerableExt
    {
        public static IDictionary<string, string> AppSettings(this IEnumerable<InstanceComponentConfiguration> instances, string server)
        {
            return instances.SingleOrDefault(_ => _.Name == server)?.AppSettings ?? new Dictionary<string, string>();
        }
    }

}