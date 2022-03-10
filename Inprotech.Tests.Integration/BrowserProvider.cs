using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Chrome;
using OpenQA.Selenium.Firefox;
using OpenQA.Selenium.IE;
using Protractor;

namespace Inprotech.Tests.Integration
{
    public static class BrowserProvider
    {
        const int TimeoutSeconds = 100;
        const int DebugTimeoutSeconds = 150;

        static InternetExplorerDriverService _ieService;
        static IWebDriver _ie;
        static NgWebDriver _ngIe;

        static IWebDriver _chrome;
        static NgWebDriver _ngChrome;

        static IWebDriver _ff;
        static NgWebDriver _ngFf;

        internal static readonly Dictionary<string, BrowserType> Browsers =
            new Dictionary<string, BrowserType>(StringComparer.InvariantCultureIgnoreCase)
            {
                {"internet explorer", BrowserType.Ie},
                {"chrome", BrowserType.Chrome},
                {"firefox", BrowserType.FireFox}
            };

        public static NgWebDriver Chrome
        {
            get
            {
                if (_ngChrome != null) return _ngChrome;

                var options = new ChromeOptions();
                var arguments = new List<string>
                {
                    "chrome.switches", "--disable-extensions"
                };
                if (Env.UseHeadlessChrome)
                {
                    arguments.AddRange(new[] { "--headless", "--lang=en-GB", "--disable-gpu", "--no-sandbox", "--window-size=1920,1200" });
                    if (Debugger.IsAttached)
                    {
                        arguments.Add("--remote-debugging-port=9222");
                    }
                }

                options.AddArguments(arguments);
                options.AddUserProfilePreference("profile.default_content_setting_values.automatic_downloads", 1);
                options.AddAdditionalCapability("useAutomationExtension", false);
                options.AcceptInsecureCertificates = true;
                
                var alternate = new FileInfo(@"C:\Program Files (x86)\Google\Chrome\Application\Chrome1.exe");
                if (alternate.Exists)
                {
                    options.BinaryLocation = alternate.FullName;
                }

                var service = ChromeDriverService.CreateDefaultService(Runtime.BrowserDriverLocations.Chrome);
                service.EnableVerboseLogging = false;
                service.SuppressInitialDiagnosticInformation = true;
                _chrome = new ChromeDriver(service, options);
                _chrome.Manage().Timeouts().AsynchronousJavaScript = TimeSpan.FromSeconds(Debugger.IsAttached ? DebugTimeoutSeconds : TimeoutSeconds);
                _chrome.Manage().Timeouts().PageLoad = TimeSpan.FromSeconds(TimeoutSeconds);

                if (Env.UseHeadlessChrome)
                {
                    var param = new Dictionary<string, object>()
                    {
                        {"behavior", "allow" },
                        {"downloadPath", KnownFolders.GetPath(KnownFolder.Downloads) }
                    };
                    ((ChromeDriver)_chrome).ExecuteChromeCommand("Page.setDownloadBehavior", param);
                }

                _ngChrome = new NgWebDriver(_chrome);
                ArrangeOnScreen(_ngChrome);

                return _ngChrome;
            }
        }

        public static NgWebDriver InternetExplorer
        {
            get
            {
                if (_ngIe != null) return _ngIe;

                var options = new InternetExplorerOptions
                              {
                                  EnableNativeEvents = false,
                                  RequireWindowFocus = true,
                                  IntroduceInstabilityByIgnoringProtectedModeSettings = true,
                                  EnsureCleanSession = true,
                                  IgnoreZoomLevel = true,
                                  AcceptInsecureCertificates = true,
                                  UnhandledPromptBehavior = UnhandledPromptBehavior.Dismiss
                              };

                _ieService = InternetExplorerDriverService.CreateDefaultService(Runtime.BrowserDriverLocations.InternetExplorer);

                _ie = new InternetExplorerDriver(_ieService, options, TimeSpan.FromMinutes(2));
                _ie.Manage().Timeouts().AsynchronousJavaScript = TimeSpan.FromSeconds(Debugger.IsAttached ? DebugTimeoutSeconds : TimeoutSeconds);
                _ie.Manage().Timeouts().PageLoad = TimeSpan.FromSeconds(TimeoutSeconds);
                _ngIe = new NgWebDriver(_ie);
                ArrangeOnScreen(_ngIe);

                return _ngIe;
            }
        }

        public static NgWebDriver Firefox
        {
            get
            {
                if (_ngFf != null) return _ngFf;
                
                var service = FirefoxDriverService.CreateDefaultService(Runtime.BrowserDriverLocations.FireFox);
                service.FirefoxBinaryPath = Runtime.Browser.FireFoxBinaryLocation;
                
                var options = new FirefoxOptions{Profile = new FirefoxProfile()};
                options.Profile.SetPreference("browser.download.folderList", 2);
                options.Profile.SetPreference("browser.download.dir", KnownFolders.GetPath(KnownFolder.Downloads));
                options.Profile.SetPreference("browser.helperApps.neverAsk.saveToDisk", "application/vnd.ms-excel");
                options.UnhandledPromptBehavior = UnhandledPromptBehavior.DismissAndNotify;
                options.LogLevel = FirefoxDriverLogLevel.Trace;
                options.AcceptInsecureCertificates = true;

                _ff = new FirefoxDriver(service, options, TimeSpan.FromSeconds(Debugger.IsAttached ? DebugTimeoutSeconds : TimeoutSeconds));
                
                Try.Do(() => _ff.Manage().Timeouts().AsynchronousJavaScript = TimeSpan.FromSeconds(Debugger.IsAttached ? DebugTimeoutSeconds : TimeoutSeconds));
                Try.Do(() => _ff.Manage().Timeouts().PageLoad = TimeSpan.FromSeconds(TimeoutSeconds));

                _ngFf = new NgWebDriver(_ff);
                ArrangeOnScreen(_ngFf);

                return _ngFf;
            }
        }

        public static NgWebDriver Get(BrowserType browserType)
        {
            switch (browserType)
            {
                case BrowserType.Ie:
                    return InternetExplorer;
                case BrowserType.Chrome:
                    return Chrome;
                case BrowserType.FireFox:
                    return Firefox;
            }

            throw new ArgumentException();
        }

        public static NgWebDriver Get(string byName)
        {
            return Get(Browsers[byName]);
        }
        
        public static void CloseBrowsers()
        {
            const string clearLocalStorageScript = @"
                if (window && window.localStorage) {
                    window.localStorage.clear();
                }";

            if (_ngChrome != null)
            {
                Try.Do(() => _ngChrome.ExecuteScript(clearLocalStorageScript));
                Try.Do(() => _ngChrome.Quit());
                _ngChrome = null;
            }

            if (_ngIe != null)
            {
                Try.Do(() => _ngIe.ExecuteScript(clearLocalStorageScript));
                Try.Do(() => _ngIe.Quit());
                _ngIe = null;
            }

            if (_ieService != null)
            {
                Try.Do(() => _ieService.Dispose());
                _ieService = null;
            }

            if (_ngFf != null)
            {
                Try.Do(() => _ngFf.ExecuteScript(clearLocalStorageScript));

                Try.Do(() => _ngFf.Quit());
                _ngFf = null;
            }
        }

        public static void ArrangeOnScreen(NgWebDriver driver)
        {
            var secondary = Screen.AllScreens.FirstOrDefault(x => !x.Primary);
            if (secondary == null)
            {
                driver.Manage().Window.Maximize();
            }
            else
            {
                // move to secondary screen

                driver.Manage().Window.Position = secondary.Bounds.Location;
                driver.Manage().Window.Size = secondary.Bounds.Size;
            }
        }
    }
}
