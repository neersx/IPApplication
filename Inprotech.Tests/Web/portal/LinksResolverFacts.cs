using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Portal;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Portal
{
    public class LinksResolverFacts : FactBase
    {
        public LinksResolverFacts()
        {
            _myLinkCategory = new TableCode((int)LinksCategory.MyLinks, (short)TableTypes.LinkCategory, "My Links").In(Db);
            _quickLinkCategory = new TableCode((int)LinksCategory.Quicklinks, (short)TableTypes.LinkCategory, "Quick Links").In(Db);
        }

        readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();
        readonly IPreferredCultureResolver _preferredCulture = Substitute.For<IPreferredCultureResolver>();
        readonly TableCode _myLinkCategory;
        readonly TableCode _quickLinkCategory;

        LinksResolver CreateSubject(User user = null)
        {
            var theUser = user ?? new User(Fixture.String(), false)
            {
                AccessAccount = new AccessAccount(Fixture.String(), true).In(Db)
            }.In(Db);
            _securityContext.User.Returns(theUser);
            _preferredCulture.Resolve().Returns("en-US");
            return new LinksResolver(Db, _securityContext, _preferredCulture, new UriHelper());
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldNotReturnQuickLinksIfNoneExist(bool isInternal)
        {
            var user = new User("hello", !isInternal).In(Db);
            user.AccessAccount = new AccessAccount(Fixture.String(), isInternal).In(Db);

            new Link(_myLinkCategory, "https://www.cpaglobal.com", isExternal: !isInternal, user: user).In(Db);

            var subject = CreateSubject(user);

            var r = (await subject.Resolve()).ToDictionary(_ => _.Group, _ => _.Links);

            Assert.False(r.ContainsKey("Quick Links"));
            Assert.True(r.ContainsKey("My Links"));
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldReturnMyLinksOrderByDisplaySequence(bool isInternal)
        {
            var user = new User("hello", !isInternal).In(Db);
            user.AccessAccount = new AccessAccount(Fixture.String(), isInternal).In(Db);

            new Link(_myLinkCategory, "https://www.cpaglobal.com/2", isExternal: !isInternal, user: user, displaySequence: 2).In(Db);
            new Link(_myLinkCategory, "https://www.cpaglobal.com/1", isExternal: !isInternal, user: user, displaySequence: 1).In(Db);
            new Link(_myLinkCategory, "https://www.cpaglobal.com/3", isExternal: !isInternal, user: user, displaySequence: 3).In(Db);

            var subject = CreateSubject(user);

            var r = (await subject.Resolve()).SelectMany(_ => _.Links).Select(_ => _.Url.ToString()).ToArray();

            Assert.Equal("https://www.cpaglobal.com/1", r[0]);
            Assert.Equal("https://www.cpaglobal.com/2", r[1]);
            Assert.Equal("https://www.cpaglobal.com/3", r[2]);
        }

        [Fact]
        public async Task ShouldNotReturnMyLinksGroupIfNoneExist()
        {
            new Link(_quickLinkCategory, "https://www.cpaglobal.com").In(Db);

            var subject = CreateSubject();

            var r = (await subject.Resolve()).ToDictionary(_ => _.Group, _ => _.Links);

            Assert.True(r.ContainsKey("Quick Links"));
            Assert.False(r.ContainsKey("My Links"));
        }

        [Fact]
        public async Task ShouldReturnLinksBelongingToUserAccessAccount()
        {
            var externalUser = new User("hello", true).In(Db);
            externalUser.AccessAccount = new AccessAccount(Fixture.String()).In(Db);

            new Link(_quickLinkCategory, "https://specific.account/1", isExternal: true, displaySequence: 2, accessAccount: externalUser.AccessAccount).In(Db);
            new Link(_quickLinkCategory, "https://general.com/1", isExternal: true, displaySequence: 1).In(Db);
            new Link(_quickLinkCategory, "https://specific.account/2", isExternal: true, displaySequence: 3, accessAccount: externalUser.AccessAccount).In(Db);
            new Link(_quickLinkCategory, "https://general.com/2", isExternal: true, displaySequence: 1).In(Db);
            new Link(_quickLinkCategory, "https://specific.account/3", isExternal: true, displaySequence: 4, accessAccount: externalUser.AccessAccount).In(Db);

            var subject = CreateSubject(externalUser);

            var r = (await subject.Resolve()).SelectMany(_ => _.Links).Select(_ => _.Url.ToString()).ToArray();

            Assert.Equal("https://specific.account/1", r[0]);
            Assert.Equal("https://specific.account/2", r[1]);
            Assert.Equal("https://specific.account/3", r[2]);

            Assert.Equal(3, r.Length);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldReturnQuickLinksOrderByDisplaySequence(bool includeAccessAccount)
        {
            var externalUser = new User("hello", true).In(Db);
            externalUser.AccessAccount = new AccessAccount(Fixture.String()).In(Db);

            var aa = includeAccessAccount ? externalUser.AccessAccount : null;

            new Link(_quickLinkCategory, "https://www.cpaglobal.com/2", isExternal: true, displaySequence: 2, accessAccount: aa).In(Db);
            new Link(_quickLinkCategory, "https://www.cpaglobal.com/1", isExternal: true, displaySequence: 1, accessAccount: aa).In(Db);
            new Link(_quickLinkCategory, "https://www.cpaglobal.com/3", isExternal: true, displaySequence: 3, accessAccount: aa).In(Db);

            var subject = CreateSubject(externalUser);

            var r = (await subject.Resolve()).SelectMany(_ => _.Links).Select(_ => _.Url.ToString()).ToArray();

            Assert.Equal("https://www.cpaglobal.com/1", r[0]);
            Assert.Equal("https://www.cpaglobal.com/2", r[1]);
            Assert.Equal("https://www.cpaglobal.com/3", r[2]);
        }
    }
}