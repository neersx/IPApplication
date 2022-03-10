using Inprotech.Infrastructure.SearchResults.Exporters;
using Xunit;

namespace Inprotech.Tests.Web.SearchResults.Exporters
{
    public class UserColumnUrlResolverFacts : FactBase
    {
        public class UserColumnUrlResolverFixture : IFixture<IUserColumnUrlResolver>
        {
            public UserColumnUrlResolverFixture()
            {
                Subject = new UserColumnUrlResolver();
            }

            public IUserColumnUrlResolver Subject { get; }
        }

        [Fact]
        public void UserColumnUrlResolverFact()
        {
            var f = new UserColumnUrlResolverFixture();
            var result = f.Subject.Resolve("http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-486");

            Assert.Equal(string.Empty, result.DisplayText);

            result = f.Subject.Resolve("[Case 1234/A Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-487]");

            Assert.Equal("Case 1234/A Link", result.DisplayText);
        }
    }
}