using System.Collections.Generic;
using System.Linq;
using Inprotech.Setup.Core;

namespace Inprotech.Setup
{
    public interface IService
    {
        IEnumerable<WebAppInfoWrapper> FindAllWebApps();
        IEnumerable<IisAppInfo> FindAllUnpairedIisApps();
        WebAppInfoWrapper FindWebApp(IisAppInfo iisApp);
    }

    class Service : IService
    {
        readonly IIisAppInfoManager _iisAppInfoManager;
        readonly IWebAppInfoManager _webAppInfoManager;
        readonly IWebAppPairingService _webAppPairingService;
        readonly WebAppInfoWrapper.Factory _createWrapper;

        public Service(IIisAppInfoManager iisAppInfoManager, IWebAppInfoManager webAppInfoManager,
            IWebAppPairingService webAppPairingService,
            WebAppInfoWrapper.Factory createWrapper)
        {
            _iisAppInfoManager = iisAppInfoManager;
            _webAppInfoManager = webAppInfoManager;
            _webAppPairingService = webAppPairingService;
            _createWrapper = createWrapper;
        }

        public IEnumerable<WebAppInfoWrapper> FindAllWebApps()
        {
            var iisApps = _iisAppInfoManager.FindAll().ToArray();
            var webApps = _webAppInfoManager.FindAll(Constants.DefaultRootPath).ToArray();

            foreach (var webApp in webApps)
            {
                var iisApp = _webAppPairingService.FindPairedIisApp(iisApps, webApp);
                yield return _createWrapper(webApp, iisApp);
            }
        }

        public IEnumerable<IisAppInfo> FindAllUnpairedIisApps()
        {
            var iisApps = _iisAppInfoManager.FindAll().ToArray();
            var webApps = _webAppInfoManager.FindAll(Constants.DefaultRootPath).ToArray();

            return _webAppPairingService.FindUnpairedIisApp(webApps, iisApps);
        }

        public WebAppInfoWrapper FindWebApp(IisAppInfo iisApp)
        {
            var webApps = _webAppInfoManager.FindAll(Constants.DefaultRootPath).ToArray();
            var webApp = _webAppPairingService.FindPairedWebApp(webApps, iisApp);
            return _createWrapper(webApp, iisApp);
        }
    }
}