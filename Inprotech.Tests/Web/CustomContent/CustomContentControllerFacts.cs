using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.CustomContent;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CustomContent
{
    public class CustomContentControllerFacts
    {
        public class ResolveMethod : FactBase
        {
            [Fact]
            public void ShouldCallResolveMethod()
            {
                var @case = new CaseBuilder().Build().In(Db);

                var f = new CustomContentControllerFixture(Db);

                var result = new CustomContentData();
                f.CustomContentDataResolver.Resolve(Arg.Any<int>(), Arg.Any<string>()).Returns(result);

                var r = f.Subject.GetCustomContentData(@case.Id, 1);

                f.CustomContentDataResolver.Received(1)
                 .Resolve(1, @case.Irn);

                Assert.Equal(result, r);
            }
        }
    }

    class CustomContentControllerFixture : IFixture<CustomContentController>
    {
        public ICustomContentDataResolver CustomContentDataResolver { get; }
        public InMemoryDbContext DbContext { get; }
        public CustomContentController Subject { get; }

        public CustomContentControllerFixture(InMemoryDbContext db)
        {
            DbContext = db;
            CustomContentDataResolver = Substitute.For<ICustomContentDataResolver>();
            Subject = new CustomContentController(DbContext, CustomContentDataResolver);
        }
    }
}
