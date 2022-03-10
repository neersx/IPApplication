using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class ConfigureThirdPartyScriptHooks : ISetupAction
    {
        readonly IFileSystem _fileSystem;
        public bool ContinueOnException => false;

        public string Description => "Configure 3rd party script hooks";

        public ConfigureThirdPartyScriptHooks(IFileSystem fileSystem)
        {
            _fileSystem = fileSystem;
        }

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            const string signinIndexHtml = "Inprotech.Server\\client\\signin\\index.html";
            const string declarationHtml = "Inprotech.Server\\client\\cookieDeclaration.html";

            var ctx = (SetupContext)context;
            var declarationBannerHook = ctx.CookieConsentSettings?.CookieDeclarationHook;
            var signinHooks = SigninHooks(ctx);

            IndexHtml(ctx, signinHooks, signinIndexHtml);
            IndexHtml(ctx, declarationBannerHook, declarationHtml);

            eventStream.PublishInformation("Completed configuration of 3rd party script hook");
        }

        void IndexHtml(SetupContext ctx, string hook, string signinIndexHtml)
        {
            const string start = "<!--! START placeholder 3rd-party-script-hooks -->";
            const string end = "<!--! END placeholder 3rd-party-script-hooks -->";

            var target = Path.Combine(ctx.InstancePath, signinIndexHtml);

            var indexHtml = _fileSystem.ReadAllText(target);

            var startIndex = indexHtml.IndexOf(start, StringComparison.Ordinal) + start.Length + 1;
            var endIndex = indexHtml.LastIndexOf(end, StringComparison.Ordinal);

            if (startIndex != endIndex)
            {
                indexHtml = indexHtml.Remove(startIndex, endIndex - startIndex);
            }

            if (!string.IsNullOrWhiteSpace(hook))
            {
                indexHtml = indexHtml.Insert(startIndex, hook);
            }

            _fileSystem.WriteAllText(target, indexHtml);
        }

        string SigninHooks(SetupContext ctx)
        {
            string replaceText = "REPLACE";
            string resetCookieBannerScript = $"<script type=\"text/javascript\">\r\nfunction inproShowCookieBanner(){{\r\n {replaceText} \r\n}}\r\n</script>";
            string cookieVerificationScript = $"<script type=\"text/javascript\">\r\nfunction inproCookieConsent(){{\r\n return {{{replaceText}}} \r\n}}\r\n</script>";

            var hook = ctx.CookieConsentSettings?.CookieConsentBannerHook;
            if (!string.IsNullOrEmpty(ctx.CookieConsentSettings?.CookieResetConsentHook))
            {
                hook += Environment.NewLine + resetCookieBannerScript.Replace(replaceText, ctx.CookieConsentSettings?.CookieResetConsentHook);
            }

            var consent = ctx.CookieConsentSettings?.CookieConsentVerificationHook;
            var preference = ctx.CookieConsentSettings?.PreferenceConsentVerificationHook;
            var statistics = ctx.CookieConsentSettings?.StatisticsConsentVerificationHook;
            if (!string.IsNullOrEmpty(consent) || !string.IsNullOrEmpty(preference) || !string.IsNullOrEmpty(statistics))
            {
                consent = "consented:" + (!string.IsNullOrEmpty(consent) ? consent : "true") + ",";
                preference = "preferenceConsented:" + (!string.IsNullOrEmpty(preference) ? preference : "true") + ",";
                statistics = "statisticsConsented:" + (!string.IsNullOrEmpty(statistics) ? statistics : "false");
                hook += Environment.NewLine + cookieVerificationScript.Replace(replaceText, consent + preference + statistics);
            }

            return hook;
        }
    }
}