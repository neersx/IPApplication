using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class ConfigureThirdPartyScriptHooksFacts
    {
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly IEventStream _eventStream = Substitute.For<IEventStream>();
        readonly string _indexHtmlPath = Path.Combine("a", "Inprotech.Server\\client\\signin\\index.html");
        readonly string _cookieDeclarationPath = Path.Combine("a", "Inprotech.Server\\client\\cookieDeclaration.html");
        readonly IDictionary<string, object> _context = new SetupContext { InstancePath = "a" };

        const string IndexHook1 = @"<link rel=""stylesheet"" type=""text/css"" href=""//cdnjs.cloudflare.com/ajax/libs/cookieconsent2/3.1.0/cookieconsent.min.css"" />
        <script src=""//cdnjs.cloudflare.com/ajax/libs/cookieconsent2/3.1.0/cookieconsent.min.js""></script>
        <script>
        window.addEventListener(""load"", function(){
            window.cookieconsent.initialise({
                ""palette"": {
                    ""popup"": {
                        ""background"": ""#000""
                    },
                    ""button"": {
                        ""background"": ""#f1d600""
                    }
                }
            })});
        </script>
";

        const string IndexHook2 = @"<script id=""Cookiebot"" src=""https://consent.cookiebot.com/uc.js"" data-cbid=""b8548a69-b031-4c99-bf10-9348755602db"" type=""text/javascript"" async></script>";

        const string IndexHtmlStart = @"<!DOCTYPE html> <html> <head> <title>Inprotech</title> <!--! START placeholder 3rd-party-script-hooks --> ";
        const string IndexHtmlEnd = @"<!--! END placeholder 3rd-party-script-hooks --> <link rel=""stylesheet"" href=""../styles/signin-app.min.7b8b9cf3.css""></head> <body ng-strict-di=""""><script src=""lib.min.3228aaf0.js""></script><script src=""app.min.42eca297.js""></script></body> </html>";
        const string DefaultIndexHtml = IndexHtmlStart + IndexHtmlEnd;
        const string IndexHtmlWithHook1 = IndexHtmlStart + IndexHook1 + IndexHtmlEnd;
        const string IndexHtmlWithHook2 = IndexHtmlStart + IndexHook2 + IndexHtmlEnd;

        const string CookieDeclarationHook1 = "<script type=\"text/javascript\" id=\"CookieDeclaration\" src=\"https://consent.cookiebot.com/fe2776a3-3ec5-4712-8795-19d62f0a514b/cd.js\" async=\"\"></script>'";
        const string CookieDeclarationHook2 = "<div id=\"optanon-cookie-policy\"></div>";

        const string CookieDeclarationHtmlStart = @"<!DOCTYPE html> <html> <head> <title>Inprotech Cookie Declaration</title> <!--! START placeholder 3rd-party-script-hooks --> ";
        const string CookieDeclarationHtmlEnd = @"<!--! END placeholder 3rd-party-script-hooks --> <link rel=""stylesheet"" href=""../styles/signin-app.min.7b8b9cf3.css""></head> <body ng-strict-di=""""><script src=""lib.min.3228aaf0.js""></script><script src=""app.min.42eca297.js""></script></body> </html>";
        const string DefaultCookieDeclarationHtml = CookieDeclarationHtmlStart + CookieDeclarationHtmlEnd;
        const string CookieDeclarationHtmlWithHook1 = CookieDeclarationHtmlStart + CookieDeclarationHook1 + CookieDeclarationHtmlEnd;
        const string CookieDeclarationHtmlWithHook2 = CookieDeclarationHtmlStart + CookieDeclarationHook2 + CookieDeclarationHtmlEnd;

        ConfigureThirdPartyScriptHooks CreateSubject(string indexHtml = DefaultIndexHtml, string cookieDeclarationHtml = DefaultCookieDeclarationHtml)
        {
            _fileSystem.ReadAllText(_indexHtmlPath).Returns(indexHtml);
            _fileSystem.ReadAllText(_cookieDeclarationPath).Returns(cookieDeclarationHtml);
            return new ConfigureThirdPartyScriptHooks(_fileSystem);
        }

        [Theory]
        [InlineData(IndexHook1, IndexHtmlWithHook1)]
        [InlineData(IndexHook2, IndexHtmlWithHook2)]
        public void ShouldAddScriptHook(string hook, string expectedIndexHtmlResult)
        {
            _context["CookieConsentSettings"] = new CookieConsentSettings { CookieConsentBannerHook = hook };

            CreateSubject().Run(_context, _eventStream);

            _fileSystem.Received(1).WriteAllText(_indexHtmlPath, expectedIndexHtmlResult);
        }

        [Fact]
        public void ShouldAddResetCookieBannerScriptHook()
        {
            var cookieResetScript = "abc.xyz();";
            string resetCookieBannerScript = $"<script type=\"text/javascript\">\r\nfunction inproShowCookieBanner(){{\r\n {cookieResetScript} \r\n}}\r\n</script>";
            _context["CookieConsentSettings"] = new CookieConsentSettings
            {
                CookieConsentBannerHook = IndexHook1,
                CookieResetConsentHook = cookieResetScript
            };

            CreateSubject().Run(_context, _eventStream);

            _fileSystem.Received(1).WriteAllText(_indexHtmlPath, IndexHtmlStart + IndexHook1 + Environment.NewLine + resetCookieBannerScript + IndexHtmlEnd);
        }

        [Theory]
        [InlineData("abc", null, null)]
        [InlineData(null, "abc", null)]
        [InlineData("abc", "xyz", null)]
        [InlineData("abc", null, "xyz")]
        [InlineData(null, null, "xyz")]
        public void ShouldAddCookieVerificationScriptHook(string consent, string preference, string statistics)
        {
            string cookieVerificationScript = $"<script type=\"text/javascript\">\r\nfunction inproCookieConsent(){{\r\n return {{consented:{consent ?? "true"},preferenceConsented:{preference ?? "true"},statisticsConsented:{statistics ?? "false"}}} \r\n}}\r\n</script>";
            _context["CookieConsentSettings"] = new CookieConsentSettings
            {
                CookieConsentBannerHook = IndexHook1,
                CookieConsentVerificationHook = consent,
                PreferenceConsentVerificationHook = preference,
                StatisticsConsentVerificationHook = statistics
            };

            CreateSubject().Run(_context, _eventStream);

            _fileSystem.Received(1).WriteAllText(_indexHtmlPath, IndexHtmlStart + IndexHook1 + Environment.NewLine + cookieVerificationScript + IndexHtmlEnd);
        }

        [Theory]
        [InlineData(CookieDeclarationHook1, CookieDeclarationHtmlWithHook1)]
        [InlineData(CookieDeclarationHook2, CookieDeclarationHtmlWithHook2)]
        public void ShouldAddDeclarationScriptHook(string hook, string expectedDeclarationHtmlResult)
        {
            _context["CookieConsentSettings"] = new CookieConsentSettings { CookieDeclarationHook = hook };

            CreateSubject().Run(_context, _eventStream);

            _fileSystem.Received(1).WriteAllText(_cookieDeclarationPath, expectedDeclarationHtmlResult);
        }

        [Fact]
        public void ShouldHaveAppropriateDescription()
        {
            Assert.Equal("Configure 3rd party script hooks", CreateSubject().Description);
        }

        [Theory]
        [InlineData(IndexHook1, IndexHtmlWithHook1, IndexHtmlWithHook1)]
        [InlineData(IndexHook2, IndexHtmlWithHook2, IndexHtmlWithHook2)]
        [InlineData("", DefaultIndexHtml, DefaultIndexHtml)]
        public void ShouldLeaveIndexUnchanged(string hook, string existingIndexHtml, string expectedModifiedIndexHtml)
        {
            _context["CookieConsentSettings"] = new CookieConsentSettings { CookieConsentBannerHook = hook };

            CreateSubject(existingIndexHtml).Run(_context, _eventStream);

            _fileSystem.Received(1).WriteAllText(_indexHtmlPath, expectedModifiedIndexHtml);
        }

        [Theory]
        [InlineData(CookieDeclarationHook1, CookieDeclarationHtmlWithHook1, CookieDeclarationHtmlWithHook1)]
        [InlineData(CookieDeclarationHook2, CookieDeclarationHtmlWithHook2, CookieDeclarationHtmlWithHook2)]
        [InlineData("", DefaultCookieDeclarationHtml, DefaultCookieDeclarationHtml)]
        public void ShouldLeaveDeclarationUnchanged(string hook, string existingDeclarationHtml, string expectedModifiedDeclarationHtml)
        {
            _context["CookieConsentSettings"] = new CookieConsentSettings { CookieDeclarationHook = hook };

            CreateSubject(cookieDeclarationHtml: existingDeclarationHtml).Run(_context, _eventStream);

            _fileSystem.Received(1).WriteAllText(_cookieDeclarationPath, expectedModifiedDeclarationHtml);
        }

        [Fact]
        public void ShouldNotContinueOnException()
        {
            Assert.False(CreateSubject().ContinueOnException);
        }

        [Theory]
        [InlineData(IndexHtmlWithHook1)]
        [InlineData(IndexHtmlWithHook2)]
        public void ShouldRemoveScriptHook(string existingIndexHtml)
        {
            _context["CookieConsentSettings"] = new CookieConsentSettings { CookieConsentBannerHook = string.Empty };

            CreateSubject(existingIndexHtml).Run(_context, _eventStream);

            _fileSystem.Received(1).WriteAllText(_indexHtmlPath, DefaultIndexHtml);
        }

        [Theory]
        [InlineData(CookieDeclarationHtmlWithHook1)]
        [InlineData(CookieDeclarationHtmlWithHook2)]
        public void ShouldRemoveDeclarationScriptHook(string existingDeclarationHtml)
        {
            _context["CookieConsentSettings"] = new CookieConsentSettings { CookieDeclarationHook = string.Empty };

            CreateSubject(cookieDeclarationHtml: existingDeclarationHtml).Run(_context, _eventStream);

            _fileSystem.Received(1).WriteAllText(_cookieDeclarationPath, DefaultCookieDeclarationHtml);
        }

        [Theory]
        [InlineData(IndexHook2, IndexHtmlWithHook1, IndexHtmlWithHook2)]
        [InlineData(IndexHook1, IndexHtmlWithHook2, IndexHtmlWithHook1)]
        public void ShouldUpdateScriptHook(string hook, string existingIndexHtml, string expectedModifiedIndexHtml)
        {
            _context["CookieConsentSettings"] = new CookieConsentSettings { CookieConsentBannerHook = hook };

            CreateSubject(existingIndexHtml).Run(_context, _eventStream);

            _fileSystem.Received(1).WriteAllText(_indexHtmlPath, expectedModifiedIndexHtml);
        }

        [Theory]
        [InlineData(CookieDeclarationHook2, CookieDeclarationHtmlWithHook1, CookieDeclarationHtmlWithHook2)]
        [InlineData(CookieDeclarationHook1, CookieDeclarationHtmlWithHook2, CookieDeclarationHtmlWithHook1)]
        public void ShouldUpdateDeclarationScriptHook(string hook, string existingDeclartionHtml, string expectedModifiedDeclarationHtml)
        {
            _context["CookieConsentSettings"] = new CookieConsentSettings { CookieDeclarationHook = hook };

            CreateSubject(cookieDeclarationHtml: existingDeclartionHtml).Run(_context, _eventStream);

            _fileSystem.Received(1).WriteAllText(_cookieDeclarationPath, expectedModifiedDeclarationHtml);
        }

        [Fact]
        public void ShouldIndicateCompleted()
        {
            CreateSubject().Run(_context, _eventStream);

            _eventStream.Received(1).Publish(Arg.Is<Event>(_ => _.Details == "Completed configuration of 3rd party script hook"));
        }
    }
}