using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using Autofac;
using CommandLine;
using Inprotech.Setup.CommandLine.DevOps;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.CommandLine
{
    internal class Program
    {
        static Program()
        {
            var builder = new ContainerBuilder();
            builder.RegisterAssemblyModules(typeof(ISetupSettingsManager).Assembly);
            builder.RegisterModule<DevOpsModule>();
            Container = builder.Build();
            SetupEnvironment.IsUiMode = false;

            try
            {
                Container.Resolve<IFileSystem>().DeleteDirectory(Constants.WorkingDirectory);
            }
            catch
            {
                // ignored
            }
        }

        static IContainer Container { get; }

        static int Main(string[] args)
        {
            if (!args.Any())
            {
                args = new[] {"--help"};
            }

            var options = new Options();

            try
            {
                if (!Parser.Default.ParseArgumentsStrict(args, options, Run, () => ShowHelp(options)))
                {
                    return -1;
                }
            }
            catch (SetupFailedException)
            {
                return -1;
            }

            return 0;
        }

        static void ShowHelp(Options options)
        {
            if (options.AddOptions != null)
            {
                Console.WriteLine(options.AddOptions.GetUsage());
            }
            else if (options.UpgradeOptions != null)
            {
                Console.WriteLine(options.UpgradeOptions.GetUsage());
            }
            else if (options.RemoveOptions != null)
            {
                Console.WriteLine(options.RemoveOptions.GetUsage());
            }
            else if (options.UpdateOptions != null)
            {
                Console.WriteLine(options.UpdateOptions.GetUsage());
            }
            else if (options.ResyncOptions != null)
            {
                Console.WriteLine(options.ResyncOptions.GetUsage());
            }
            else if (options.ListOptions != null)
            {
                Console.WriteLine(options.ListOptions.GetUsage());
            }
            else if (options.ResumeOptions != null)
            {
                Console.WriteLine(options.ResumeOptions.GetUsage());
            }
            else if (options.IisOptions != null)
            {
                Console.WriteLine(options.IisOptions.GetUsage());
            }
            else
            {
                Console.WriteLine(options.GetUsage());
            }
        }

        static void Run(string verb, object options)
        {
            if (options == null)
            {
                return;
            }

            if (options is AddOptions)
            {
                Add((AddOptions) options);
            }
            else if (options is UpgradeOptions)
            {
                Upgrade((UpgradeOptions) options);
            }
            else if (options is RemoveOptions)
            {
                Remove((RemoveOptions) options);
            }
            else if (options is ResyncOptions)
            {
                Resync((ResyncOptions) options);
            }
            else if (options is UpdateOptions)
            {
                Update((UpdateOptions) options);
            }
            else if (options is ResumeOptions)
            {
                Resume((ResumeOptions) options);
            }
            else if (options is ListOptions)
            {
                ShowWebApps((ListOptions) options);
            }
            else if (options is IisOptions)
            {
                ShowIisApps((IisOptions) options);
            }
        }

        static void ShowIisApps(IisOptions options)
        {
            var iisAppManager = Container.Resolve<IiisAppInfoManagerSelector>().Select(options.IisAppInfoProfiles);
            var webAppManager = Container.Resolve<IWebAppInfoManager>();
            var pairingService = Container.Resolve<IWebAppPairingService>();
            var webApps = webAppManager.FindAll(options.RootPath).ToArray();
            var iisApps = iisAppManager.FindAll().ToArray();

            if (!iisApps.Any())
            {
                Console.WriteLine("No available Inprotech IIS Applications found.");
            }

            foreach (var iisApp in iisApps)
            {
                Console.WriteLine("ID=" + iisApp.Site + iisApp.VirtualPath);
                Console.WriteLine("Site=" + iisApp.Site);
                Console.WriteLine("Path=" + iisApp.VirtualPath);

                var appInfo = pairingService.FindPairedWebApp(webApps, iisApp);

                if (appInfo != null)
                {
                    Console.WriteLine("IsPaired=True");
                    Console.WriteLine("Instance=" + appInfo.InstanceName + "; Status=" +
                                      (appInfo.Settings.Status == SetupStatus.Complete ? "Complete" : "Incomplete"));
                }
                else
                {
                    Console.WriteLine("IsPaired=False");
                }

                Console.WriteLine();
            }
        }

        static void ShowWebApps(ListOptions options)
        {
            var iisAppManager = Container.Resolve<IiisAppInfoManagerSelector>().Select(options.IisAppInfoProfiles);
            var webAppManager = Container.Resolve<IWebAppInfoManager>();
            var pairingService = Container.Resolve<IWebAppPairingService>();
            var webApps = webAppManager.FindAll(options.RoothPath).ToArray();
            var iisApps = iisAppManager.FindAll().ToArray();

            if (!webApps.Any())
            {
                Console.WriteLine("No instances found. Run 'setup-cli add' to create one.");
                return;
            }

            foreach (var webApp in webApps)
            {
                var settings = webApp.Settings;

                Console.WriteLine("ID=" + webApp.InstanceName);
                Console.WriteLine("Path=" + webApp.FullPath);
                Console.WriteLine("Version=" + settings.Version);
                Console.WriteLine("Status=" + (settings.Status == SetupStatus.Complete ? "Complete" : "Incomplete"));

                var iisAppInfo = pairingService.FindPairedIisApp(iisApps, webApp);

                if (iisAppInfo == null)
                {
                    Console.WriteLine("IsPaired=False");
                }
                else
                {
                    Console.WriteLine("IsPaired=True");
                    Console.WriteLine("IisApp=" + settings.IisSite + settings.IisPath);
                }

                Console.WriteLine("StorageLocation=" + settings.StorageLocation);
                Console.WriteLine();
            }
        }

        static void Add(AddOptions options)
        {
            if (!options.IisAppPath.Contains('/'))
            {
                throw new Exception("Invalid IIS Application path.");
            }

            var authenticationSettings = new AuthenticationSettings
            {
                AuthenticationMode = options.AuthenticationMode,
                TwoFactorAuthenticationMode = options.Authentication2FAMode,
                IpPlatformSettings = GetIpPlatformSettings(options.ClientId, options.ClientSecret)
            };

            var context = GetContextSettings(options.StorageLocation, options.IntegrationServerPort, 
                                             new CookieConsentSettings {CookieConsentBannerHook = options.CookieConsentBannerHook},
                                             options.IisAppInfoProfiles,
                                             options.E2E, options.BypassSslCertificateCheck);

            RunSetupWorkflow(workflows =>
                                 workflows.New(options.RootPath, options.IisAppPath.Split('/')[0], '/' + options.IisAppPath.Split('/')[1],
                                               options.DatabaseUsername, options.DatabasePassword, context, authenticationSettings));
        }

        static void Remove(RemoveOptions options)
        {
            var context = GetContextSettings(iisProfile: options.IisAppInfoProfiles);

            RunSetupWorkflow(workflows =>
                                 workflows.Remove(options.InstancePath, options.DatabaseUsername, options.DatabasePassword, context));
        }

        static void Upgrade(UpgradeOptions options)
        {
            var authenticationSettings = new AuthenticationSettings
            {
                AuthenticationMode = options.AuthenticationMode,
                TwoFactorAuthenticationMode = options.Authentication2FAMode,
                IpPlatformSettings = GetIpPlatformSettings(options.ClientId, options.ClientSecret)
            };

            var context = GetContextSettings(options.StorageLocation, options.IntegrationServerPort, 
                                             new CookieConsentSettings {CookieConsentBannerHook = options.CookieConsentBannerHook}, 
                                             options.IisAppInfoProfiles,
                                             options.E2E, options.BypassSslCertificateCheck);

            RunSetupWorkflow(
                             workflows =>
                                 workflows.Upgrade(options.InstancePath, options.NewRootPath,
                                                   options.DatabaseUsername, options.DatabasePassword, context, authenticationSettings));
        }

        static void Resync(ResyncOptions options)
        {
            var context = GetContextSettings(iisProfile: options.IisAppInfoProfiles, isE2EMode: options.E2E);

            RunSetupWorkflow(
                             workflows =>
                                 workflows.Resync(options.InstancePath, options.DatabaseUsername, options.DatabasePassword, context));
        }

        static void Update(UpdateOptions options)
        {
            var authenticationSettings = new AuthenticationSettings
            {
                AuthenticationMode = options.AuthenticationMode,
                TwoFactorAuthenticationMode = options.Authentication2FAMode,
                IpPlatformSettings = GetIpPlatformSettings(options.ClientId, options.ClientSecret)
            };

            var context = GetContextSettings(options.StorageLocation, options.IntegrationServerPort, 
                                             new CookieConsentSettings {CookieConsentBannerHook = options.CookieConsentBannerHook}, 
                                             options.IisAppInfoProfiles,
                                             options.E2E, options.BypassSslCertificateCheck);

            RunSetupWorkflow(
                             workflows =>
                                 workflows.Update(options.InstancePath, options.DatabaseUsername, options.DatabasePassword, context, authenticationSettings));
        }

        static void Resume(ResumeOptions options)
        {
            var context = GetContextSettings(iisProfile: options.IisAppInfoProfiles);

            RunSetupWorkflow(
                             workflows =>
                                 workflows.Resume(options.InstancePath, options.DatabaseUsername, options.DatabasePassword, context));
        }

        static void RunSetupWorkflow(Func<ISetupWorkflows, SetupWorkflow> createWorkflow)
        {
            var consoleStream = new ConsoleStream();

            var workflows = Container.Resolve<ISetupWorkflows>();
            var workflow = createWorkflow(workflows);

            var runner = Container.Resolve<ISetupRunner>();

            runner.OnBeforeAction += action =>
            {
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine("\nAction: " + action.Description);
                Console.ResetColor();
            };

            var t = Task.Run(() => runner.Run(workflow, consoleStream));
            if (!t.Result)
            {
                consoleStream.PublishError("\nSetup failed!");
                throw new SetupFailedException();
            }

            consoleStream.PublishInformation("\nSetup complete!");
        }

        static IpPlatformSettings GetIpPlatformSettings(string clientId, string clientSecret)
        {
            return new IpPlatformSettings(clientId, clientSecret);
        }

        static ContextSettings GetContextSettings(string storageLocation = null, 
                                                  string integrationServerPort = null, 
                                                  CookieConsentSettings cookieConsentSettings = null, 
                                                  string iisProfile = null,
                                                  bool isE2EMode = false,
                                                  bool bypassSslCertificateCheck = false,
                                                  UsageStatisticsSettings usageStatisticsSettings = null)
        {
            var appSettings = Container.Resolve<IAppConfigReader>();

            return new ContextSettings
            {
                StorageLocation = storageLocation,
                PrivateKey = appSettings.PrivateKey(),
                IntegrationServerPort = integrationServerPort,
                CookieConsentSettings = cookieConsentSettings,
                UsageStatisticsSettings = usageStatisticsSettings,
                IisAppInfoProfiles = iisProfile,
                IsE2EMode = isE2EMode,
                BypassSslCertificateCheck = bypassSslCertificateCheck
            };
        }
    }

    [SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    internal class SetupFailedException : Exception
    {
    }
}