using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ValidUsersPicklistControllerFacts : FactBase
    {
        [Theory]
        [InlineData("inter")]
        [InlineData("int")]
        [InlineData("nal")]
        [InlineData("ter")]
        public void ShouldReturnsUsersContains(string query)
        {
            new User("internal", false)
            {
                IsValid = true,
                Name = new NameBuilder(Db)
                {
                    FirstName = "George",
                    LastName = "Grey"
                }.Build().In(Db)
            }.In(Db);

            var pagedResults = new ValidUsersPicklistController(Db).Search(null, query);
            var r = pagedResults.Data.ToArray();

            Assert.Single(r);
            Assert.Equal("internal", r.First().Username);
            Assert.Equal("Grey, George", r.First().Name);
        }

        [Fact]
        public void ShouldNotReturnExternalUsers()
        {
            new User("external", true)
            {
                IsValid = true,
                Name = new NameBuilder(Db)
                {
                    FirstName = "George",
                    LastName = "Grey"
                }.Build().In(Db)
            }.In(Db);

            var pagedResults = new ValidUsersPicklistController(Db).Search(null, string.Empty);
            var r = pagedResults.Data.ToArray();

            Assert.Empty(r);
        }

        [Fact]
        public void ShouldNotReturnInvalidUsers()
        {
            new User("internal", false)
            {
                IsValid = false,
                Name = new NameBuilder(Db)
                {
                    FirstName = "George",
                    LastName = "Grey"
                }.Build().In(Db)
            }.In(Db);

            var pagedResults = new ValidUsersPicklistController(Db).Search(null, string.Empty);
            var r = pagedResults.Data.ToArray();

            Assert.Empty(r);
        }

        [Fact]
        public void ShouldReturnsUsers()
        {
            new User("internal", false)
            {
                IsValid = true,
                Name = new NameBuilder(Db)
                {
                    FirstName = "George",
                    LastName = "Grey"
                }.Build().In(Db)
            }.In(Db);

            var pagedResults = new ValidUsersPicklistController(Db).Search(null, string.Empty);
            var r = pagedResults.Data.ToArray();

            Assert.Single(r);
            Assert.Equal("internal", r.First().Username);
            Assert.Equal("Grey, George", r.First().Name);
        }

        [Fact]
        public void ShouldReturnsUsersStartsWithFollowedByContains()
        {
            new User("attorney", false)
            {
                IsValid = true,
                Name = new NameBuilder(Db)
                {
                    FirstName = "Pinterest",
                    LastName = "Stark"
                }.Build().In(Db)
            }.In(Db);

            new User("internal", false)
            {
                IsValid = true,
                Name = new NameBuilder(Db)
                {
                    FirstName = "George",
                    LastName = "Grey"
                }.Build().In(Db)
            }.In(Db);

            var pagedResults = new ValidUsersPicklistController(Db).Search(null, "int");
            var r = pagedResults.Data.ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("internal", r.First().Username);
            Assert.Equal("Grey, George", r.First().Name);

            Assert.Equal("attorney", r.Last().Username);
            Assert.Equal("Stark, Pinterest", r.Last().Name);
        }
    }
}