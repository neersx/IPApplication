using System.Collections.Generic;
using System.IO;
using System.Reflection;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.TempStorage;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Customisation
{
    [TestFixture]
    [Category(Categories.E2E)]
    public class Branding : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var clientRoot = InprotechServer.ClientRoot();

            _files["client-root"] = clientRoot;
            _files["custom.css"] = File.ReadAllText(Path.Combine(clientRoot, "styles", "custom.css"));
            _files["batchEvent-custom.css"] = File.ReadAllText(Path.Combine(clientRoot, "batchEventUpdate", "custom.css"));
            _files["chicken-tonight"] = Path.Combine(clientRoot, "images", "chicken-tonight.png");

            using (var resourceStream = Assembly.GetAssembly(typeof(Program)).GetManifestResourceStream(typeof(Program).Namespace + ".Assets.chicken-tonight.png"))
            using (var output = File.OpenWrite(_files["chicken-tonight"]))
            {
                resourceStream?.CopyTo(output);
            }

            File.WriteAllText(Path.Combine(clientRoot, "styles", "custom.css"), CustomStyle);
            File.WriteAllText(Path.Combine(clientRoot, "batchEventUpdate", "custom.css"), BatchEventCustomStyle);
        }

        [TearDown]
        public void Restore()
        {
            var clientRoot = _files["client-root"];

            File.WriteAllText(Path.Combine(clientRoot, "styles", "custom.css"), _files["custom.css"]);
            File.WriteAllText(Path.Combine(clientRoot, "batchEventUpdate", "custom.css"), _files["batchEvent-custom.css"]);
            File.Delete(_files["chicken-tonight"]);
        }

        readonly Dictionary<string, string> _files = new Dictionary<string, string>
        {
            {"client-root", string.Empty},
            {"custom.css", string.Empty},
            {"batchEvent-custom.css", string.Empty}
        };

        [TestCase(BrowserType.Chrome,Ignore = "Access to physical path not available, find an alternate way to update the files")]
        public void ApplyCorporateBranding(BrowserType browserType)
        {
            var tempStorageId = DbSetup.Do(_ =>
            {
                var @case = new CaseBuilder(_.DbContext).Create();

                return _.Insert(new TempStorage($"{@case.Id}")).Id;
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/portal2");

            var condorBrandLogoUrl = driver.WithJs().ExecuteJavaScript<string>("return $('.brand-logo').css('background-image')");

            Assert.True(condorBrandLogoUrl.Contains("chicken-tonight.png"), $"Should load custom condor brand logo, but is {condorBrandLogoUrl} instead");

            driver.WithJs().ExecuteJavaScript<object>($"window.location = '{Env.RootUrl}/BatchEventUpdate/?tempStorageId={tempStorageId}';");

            var batchEventUpdateBrandLogoUrl = driver.WithJs().ExecuteJavaScript<string>("return $('.logo').css('background-image')");

            Assert.True(batchEventUpdateBrandLogoUrl.Contains("chicken-tonight.png"), $"Should load custom batch event update brand logo, but is {batchEventUpdateBrandLogoUrl} instead");
        }

        const string BatchEventCustomStyle = @"
.logo {
    background: url(../images/chicken-tonight.png) 5% 55% no-repeat;
    background-size: contain;
}
";

        const string CustomStyle = @"
.brand-logo {
    background: url('../images/chicken-tonight.png') no-repeat center;
    background-position: left top;
    background-size: cover;
    height: 2.7em;
    width: 70px;
}";
    }
}