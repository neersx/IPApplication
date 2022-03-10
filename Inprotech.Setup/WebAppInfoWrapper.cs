using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup
{
    public class WebAppInfoWrapper
    {
        public delegate WebAppInfoWrapper Factory(WebAppInfo webAppInfo, IisAppInfo iisAppInfo);

        readonly WebAppInfo _webAppInfo;
        readonly IVersionManager _versionManager;

        public WebAppInfoWrapper(WebAppInfo webAppInfo, IisAppInfo iisAppInfo, IVersionManager versionManager)
        {
            _webAppInfo = webAppInfo ?? throw new ArgumentNullException(nameof(webAppInfo));
            PairedIisAppInfo = iisAppInfo;
            _versionManager = versionManager;
        }

        public string InstanceName => _webAppInfo.InstanceName;
        
        public Version Version => _webAppInfo.Settings.Version;

        public IisAppInfo PairedIisAppInfo { get; }

        public bool IsPaired => PairedIisAppInfo != null;

        public bool CanResync => IsPaired && IsComplete && !MustUpgradeApps;

        public bool CanUpdate => IsComplete && _webAppInfo.Features.Contains("settings") && !MustUpgradeApps;

        public bool CanResume => !IsComplete && (IsPaired || RunMode == SetupRunMode.Remove);

        public bool CanUpgrade
        {
            get
            {
                if (!IsPaired)
                    return false;

                if (!IsComplete)
                    return false;

                return _versionManager.ShouldUpgradeWebApp(_webAppInfo.Settings.Version);
            }
        }

        public bool MustUpgradeApps => IsPaired && PairedIisAppInfo.AuthModeToBeSetFromApps && _versionManager.MustUpgradeWebApp(PairedIisAppInfo.Version, _webAppInfo.Settings.Version);

        public string InstancePath => _webAppInfo.FullPath;

        public SetupRunMode RunMode => _webAppInfo.Settings.RunMode;

        public bool IsComplete => _webAppInfo.Settings.Status == SetupStatus.Complete;

        public IEnumerable<InstanceComponentConfiguration> ComponentConfigurations => _webAppInfo.ComponentConfigurations;

        public string MainProductVersion => PairedIisAppInfo.Version.ToString();

        public IEnumerable<string> Features => _webAppInfo.Features;
    }
}