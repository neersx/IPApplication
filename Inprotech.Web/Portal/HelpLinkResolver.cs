using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Portal
{
    public interface IHelpLinkResolver
    {
        string Resolve();
    }
    class HelpLinkResolver : IHelpLinkResolver
    {
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;

        public HelpLinkResolver(ISecurityContext securityContext, ISiteControlReader siteControlReader)
        {
            _securityContext = securityContext;
            _siteControlReader = siteControlReader;
        }

        public string Resolve()
        {
            var link= _siteControlReader.Read<string>(_securityContext.User.IsExternalUser ? SiteControls.HelpForExternalUsers : SiteControls.HelpForInternalUsers);
            if (link.StartsWith("/"))
                link = $"..{link}";
            return link;
        }
    }
}
