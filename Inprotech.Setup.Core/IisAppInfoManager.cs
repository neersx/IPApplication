using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Security.Principal;
using Microsoft.Web.Administration;

namespace Inprotech.Setup.Core
{
    public interface IIisAppInfoManager
    {
        IEnumerable<IisAppInfo> FindAll();

        IisAppInfo Find(string site, string path);
    }

    internal class IisAppInfoManager : IIisAppInfoManager
    {
        readonly string _defaultServiceUser;
        readonly IFileSystem _fileSystem;
        readonly Func<ServerManager> _serverManagerFunc;
        readonly IVersionManager _versionManager;
        readonly IWebConfigReader _webConfigReader;

        public IisAppInfoManager(
            Func<ServerManager> serverManagerFunc,
            IWebConfigReader webConfigReader,
            IFileSystem fileSystem,
            IVersionManager versionManager)
        {
            _serverManagerFunc = serverManagerFunc;
            _webConfigReader = webConfigReader;
            _fileSystem = fileSystem;
            _versionManager = versionManager;
            _defaultServiceUser = new SecurityIdentifier("S-1-5-20").Translate(typeof(NTAccount)).Value;
        }

        public IEnumerable<IisAppInfo> FindAll()
        {
            return Find((s, a) => true);
        }

        public IisAppInfo Find(string site, string path)
        {
            var result =
                Find(
                     (s, a) =>
                         string.Equals(s.Name, site, StringComparison.OrdinalIgnoreCase) &&
                         string.Equals(a.Path, path, StringComparison.OrdinalIgnoreCase)).SingleOrDefault();

            if (result == null)
            {
                throw new Exception("Iis Application not found: " + site + path);
            }

            return result;
        }

        IEnumerable<IisAppInfo> Find(Func<Site, Application, bool> predicate)
        {
            using (var mgr = _serverManagerFunc())
            {
                return (from site in mgr.Sites
                        from application in site.Applications
                        let applicationPool = mgr.ApplicationPools[application.ApplicationPoolName]
                        let isBuiltInServiceUser = applicationPool.ProcessModel.IdentityType != ProcessModelIdentityType.SpecificUser
                        from virtualDirectory in application.VirtualDirectories
                        where IsInprotechApplication(virtualDirectory.PhysicalPath) && predicate(site, application)
                        let webConfig = _webConfigReader.Read(virtualDirectory.PhysicalPath, applicationPool.ManagedPipelineMode)
                        where webConfig != null
                        select new IisAppInfo
                        {
                            Site = site.Name,
                            VirtualPath = application.Path,
                            ApplicationPool = application.ApplicationPoolName,
                            Protocols = application.EnabledProtocols,
                            BindingUrls = BuildBindings(site),
                            PhysicalPath = virtualDirectory.PhysicalPath,
                            IdentityType = applicationPool.ProcessModel.IdentityType,
                            Username = applicationPool.ProcessModel.UserName,
                            Password = applicationPool.ProcessModel.Password,
                            IsBuiltInServiceUser = isBuiltInServiceUser,
                            ServiceUser = isBuiltInServiceUser ? _defaultServiceUser : applicationPool.ProcessModel.UserName,
                            WebConfig = webConfig,
                            Version = _versionManager.GetIisAppVersion(virtualDirectory.PhysicalPath),
                            AuthModeToBeSetFromApps = _versionManager.IsAuthModeSetFromApps(_versionManager.GetIisAppVersion(virtualDirectory.PhysicalPath))
                        }).ToArray();
            }
        }

        public bool IsInprotechApplication(string path)
        {
            var file = Path.Combine(path, Constants.BinFolder, Constants.InprotechCoreDll);
            return _fileSystem.FileExists(file);
        }

        static string BuildBindings(Site site)
        {
            var bindings = new List<string>();
            foreach (var binding in site.Bindings)
            {
                var protocol = binding.Protocol.ToLower();

                if (protocol == "http" || protocol == "https")
                {
                    var host = binding.Host;
                    var ip = binding.EndPoint;
                    if (string.IsNullOrEmpty(host))
                    {
                        host = ip.Address.Equals(IPAddress.Any) ? "*" : ip.Address.ToString();
                        if (ip.AddressFamily == AddressFamily.InterNetworkV6)
                        {
                            host = $"[{host}]";
                        }
                    }

                    bindings.Add($"{protocol}://{host}:{ip.Port}");
                }
            }

            return string.Join(",", bindings);
        }
    }
}