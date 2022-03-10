using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Portal;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Portal
{
    public class HelpLinkResolverFacts : FactBase
    {
        public HelpLinkResolverFacts()
        {
            _securityContext = Substitute.For<ISecurityContext>();
            _siteControlReader = Substitute.For<ISiteControlReader>();
            _f = new HelpLinkResolver(_securityContext, _siteControlReader);

            _siteControlReader.Read<string>(SiteControls.HelpForInternalUsers).Returns("/internal/help");
            _siteControlReader.Read<string>(SiteControls.HelpForExternalUsers).Returns("/external/help");
        }

        readonly HelpLinkResolver _f;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;

        (User @internal, User external) Users => (new User("internal", false).In(Db),
            new User("external", true).In(Db));

        [Fact]
        public void ReturnHelpLink()
        {
            _siteControlReader.Read<string>(SiteControls.HelpForInternalUsers).Returns("http://abc.com/internal/help");
            _siteControlReader.Read<string>(SiteControls.HelpForExternalUsers).Returns("http://xyz.com/external/help");

            _securityContext.User.Returns(Users.@internal);
            Assert.Equal("http://abc.com/internal/help", _f.Resolve());

            _securityContext.User.Returns(Users.external);
            Assert.Equal("http://xyz.com/external/help", _f.Resolve());
        }

        [Fact]
        public void ReturnRelativeHelpLinkForExternalUser()
        {
            _securityContext.User.Returns(Users.external);
            Assert.Equal("../external/help", _f.Resolve());
        }

        [Fact]
        public void ReturnRelativeHelpLinkForInternalUser()
        {
            _securityContext.User.Returns(Users.@internal);
            Assert.Equal("../internal/help", _f.Resolve());
        }
    }
}