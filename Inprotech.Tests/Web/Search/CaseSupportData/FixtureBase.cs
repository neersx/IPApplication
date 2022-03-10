using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using NSubstitute;

namespace Inprotech.Tests.Web.Search.CaseSupportData
{
    public abstract class FixtureBase
    {
        public const string ListCaseSupportCommand = @"EXEC csw_ListCaseSupport @p0, @p1, @p2, @p3, @p4, @p5";

        protected FixtureBase()
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            DbContext = Substitute.For<IDbContext>();
        }

        public IDbContext DbContext { get; set; }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }

        public ISecurityContext SecurityContext { get; set; }

        public FixtureBase WithUser(User user)
        {
            SecurityContext.User.Returns(user);

            return this;
        }

        public FixtureBase WithCulture(string culture)
        {
            PreferredCultureResolver.Resolve().Returns(culture);

            return this;
        }

        public FixtureBase WithSqlResults<T>(params T[] results)
        {
            DbContext.SqlQuery<T>(null).ReturnsForAnyArgs(results ?? Enumerable.Empty<T>());

            return this;
        }
    }
}