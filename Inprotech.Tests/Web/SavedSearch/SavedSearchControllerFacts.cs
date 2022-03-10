using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Portal;
using Inprotech.Web.SavedSearch;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.SavedSearch
{
    public class SavedSearchControllerFacts
    {
        [Theory]
        [InlineData(2, ApplicationTask.RunSavedCaseSearch)]

        public void CheckSecurity(QueryContext queryContextKey, ApplicationTask permissionTask)
        {
            var f = new SavedSearchControllerFixture();

            f.TaskSecurityProvider.ListAvailableTasks().Returns(
                         new [] { permissionTask }
                         .Select(ps => new ValidSecurityTask((short)ps, false, false, false, true)));

            f.SavedSearchMenu.Build(queryContextKey, string.Empty).Returns(new[] {new AppsMenu.AppsMenuItem("1", "#/case/Search/1", string.Empty, string.Empty),});

            var r = f.Subject.Menu(queryContextKey);
            Assert.Equal(1, r.Length);
            Assert.Equal("1", r[0].Key);
        }

        [Fact]
        public void ThrowsExceptionWhenTaskNotProvided()
        {
            var f = new SavedSearchControllerFixture();

            const QueryContext unsupportedForMenuNow = QueryContext.AccessAccountPickList;

            Assert.Throws<System.Web.HttpException>(() => { f.Subject.Menu(unsupportedForMenuNow); });
        }
    }

    class SavedSearchControllerFixture : IFixture<SavedSearchController>
    {
        public ISavedSearchMenu SavedSearchMenu { get; }

        public ITaskSecurityProvider TaskSecurityProvider { get; }

        public SavedSearchController Subject { get; }

        public SavedSearchControllerFixture()
        {
            SavedSearchMenu = Substitute.For<ISavedSearchMenu>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            Subject = new SavedSearchController(SavedSearchMenu, TaskSecurityProvider);
        }
    }
}
