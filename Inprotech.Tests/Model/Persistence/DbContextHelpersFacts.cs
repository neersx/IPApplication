using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Persistence
{
    public class DbContextHelpersFacts
    {
        public DbContextHelpersFacts()
        {
            _dbContext = Substitute.For<IDbContext>();
        }

        readonly IDbContext _dbContext;

        [Fact]
        public void ShouldBuildDynamicArgumentNamesInSqlCommand()
        {
            DbContextHelpers.ExecuteSqlQuery<int>(_dbContext, "sproc", 1, "a");

            _dbContext.Received(1).SqlQuery<int>("EXEC sproc @p0, @p1", Arg.Any<object[]>());
        }

        [Fact]
        public void ShouldForwardArguments()
        {
            var arguments = new object[0];

            DbContextHelpers.ExecuteSqlQuery<int>(_dbContext, string.Empty, arguments);

            _dbContext.Received(1).SqlQuery<int>(Arg.Any<string>(), arguments);
        }
    }
}