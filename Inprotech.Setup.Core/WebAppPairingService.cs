using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Setup.Core
{
    public interface IWebAppPairingService
    {
        IisAppInfo FindPairedIisApp(IEnumerable<IisAppInfo> iisApps, WebAppInfo webApp);
        WebAppInfo FindPairedWebApp(IEnumerable<WebAppInfo> webApps, IisAppInfo iisApp);
        IEnumerable<IisAppInfo> FindUnpairedIisApp(IEnumerable<WebAppInfo> webApps, IEnumerable<IisAppInfo> iisApps);
    }

    class WebAppPairingService : IWebAppPairingService
    {
        public IisAppInfo FindPairedIisApp(IEnumerable<IisAppInfo> iisApps, WebAppInfo webApp)
        {
            if (webApp.Settings == null)
                return null;

            if (webApp.IsBrokenInstance)
                return FindBrokenPairedIisApp(iisApps, webApp);

            foreach (var iisApp in iisApps)
            {
                if (string.Equals(iisApp.Site, webApp.Settings.IisSite, StringComparison.OrdinalIgnoreCase)
                    && string.Equals(iisApp.VirtualPath, webApp.Settings.IisPath, StringComparison.OrdinalIgnoreCase))
                    return iisApp;
            }

            return null;
        }

        public WebAppInfo FindPairedWebApp(IEnumerable<WebAppInfo> webApps, IisAppInfo iisApp)
        {
            foreach (var webApp in webApps)
            {
                if (webApp.IsBrokenInstance && FindBrokenPairedIisApp(new[] { iisApp }, webApp) != null)
                    return webApp;

                if (webApp.Settings != null
                    && string.Equals(iisApp.Site, webApp.Settings.IisSite, StringComparison.OrdinalIgnoreCase)
                    && string.Equals(iisApp.VirtualPath, webApp.Settings.IisPath, StringComparison.OrdinalIgnoreCase))
                    return webApp;
            }

            return null;
        }

        public IEnumerable<IisAppInfo> FindUnpairedIisApp(IEnumerable<WebAppInfo> webApps, IEnumerable<IisAppInfo> iisApps)
        {
            webApps = webApps.ToArray();
            foreach (var iisApp in iisApps)
            {
                var webApp = FindPairedWebApp(webApps, iisApp);
                if (webApp == null)
                    yield return iisApp;
            }
        }

        IisAppInfo FindBrokenPairedIisApp(IEnumerable<IisAppInfo> iisApps, WebAppInfo webApp)
        {
            if (!webApp.IsBrokenInstance)
                return null;

            foreach (var iisApp in iisApps)
            {
                if (string.Equals(iisApp.VirtualPath.Replace("/", string.Empty), webApp.InstanceName.Split('-').First(), StringComparison.OrdinalIgnoreCase))
                    return iisApp;
            }

            return null;
        }
    }
}