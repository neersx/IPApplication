using System;
using System.IO;
using System.Linq;
using Inprotech.Setup.Core;
using Microsoft.Web.Administration;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests
{
    public class IisAppInfoManagerFacts
    {
        readonly IWebConfigReader _webConfigReader = Substitute.For<IWebConfigReader>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly IVersionManager _versionManager = Substitute.For<IVersionManager>();

        IisAppInfoManager CreateSubject(string applicationHostPath = null)
        {
            var path = applicationHostPath ?? @"Assets\ipv4.applicationHost.config";
            if (!Path.IsPathRooted(path))
            {
                path = Path.GetFullPath(path);
            }

            ServerManager Factory() => new ServerManager(true, path);

            _fileSystem.FileExists(@"C:\Program Files (x86)\CPA Global\Web Version Software\bin\Inprotech.Core.dll")
                       .Returns(true);

            var thirteenPointOne = new Version(13, 1);

            _versionManager.GetIisAppVersion(Arg.Any<string>())
                           .Returns(thirteenPointOne);

            _versionManager.IsAuthModeSetFromApps(thirteenPointOne).Returns(true);

            _webConfigReader.Read(Arg.Any<string>(), Arg.Any<ManagedPipelineMode>())
                            .Returns(new WebConfig());

            return new IisAppInfoManager(Factory, _webConfigReader, _fileSystem, _versionManager);
        }

        static Uri CreateAppsUriFromBindingUrls(string url)
        {
            var u = url.Replace("*", "localhost").TrimEnd('/') + "/cpainpro/apps";

            return new Uri(u);
        }

        /*
         * This test cannot be conducted in our CI environment because it needs IIS to be available
         * IIS interferes with TeamCity, it can be gotten around by doing this - http://mvalipour.github.io/devops/2016/08/01/setup-teamcity-reverse-proxy
         */

        //[Theory]
        //[InlineData(@"Assets\ipv4.applicationHost.config", "http://*:80")]
        //[InlineData(@"Assets\ipv6.applicationHost.config", "https://[fd9e:1c92:f8f:3333::1]:62000,https://172.21.0.158:62000,https://[fd9e:1c92:f8f:1:0:5efe:172.21.0.158]:62000")]
        public void ShouldReturnValidBindingUrls(string applicationHostConfigPath, string expectedBindingUrls)
        {
            var subject = CreateSubject(applicationHostConfigPath);

            var f = subject.FindAll().Single();
            
            Assert.Equal(expectedBindingUrls, f.BindingUrls);

            var urls = f.BindingUrls.Split(',');

            foreach (var url in urls) Assert.NotNull(CreateAppsUriFromBindingUrls(url));
        }
    }
}