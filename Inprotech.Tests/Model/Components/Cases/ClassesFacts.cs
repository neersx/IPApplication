using Inprotech.Infrastructure.Caching;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Configuration;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class ClassesFacts
    {
        public class GetLocalClassMethod : FactBase
        {
            [Fact]
            void ReturnsExistingClass()
            {
                var f = new ClassesFixture(Db)
                    .WithAvailbleClasses("AU");

                var result = f.Subject.GetLocalClass("T", "AU", "90");

                Assert.Equal("90", result.Class);
                Assert.Equal("91", result.IntClass);
            }

            [Fact]
            void ReturnsExistingClassForDefaultCountry()
            {
                var f = new ClassesFixture(Db)
                    .WithAvailbleClasses();

                var result = f.Subject.GetLocalClass("T", "AU", "90");

                Assert.Equal("90", result.Class);
                Assert.Equal("91", result.IntClass);
            }

            [Fact]
            void ReturnsExistingClassStripingZeros()
            {
                var f = new ClassesFixture(Db)
                    .WithAvailbleClasses("AU");
                var result = f.Subject.GetLocalClass("T", "AU", "009");

                Assert.Equal("09", result.Class);
            }
        }
    }

    internal class ClassesFixture : IFixture<IClasses>
    {
        readonly InMemoryDbContext _db;

        public ClassesFixture(InMemoryDbContext db)
        {
            _db = db;
            Subject = new Classes(db, new LifetimeScopeCache());
        }

        public IClasses Subject { get; }

        public ClassesFixture WithAvailbleClasses(string countryCode = "ZZZ")
        {
            new TmClass(countryCode, "09", "T") {GoodsOrService = "G", IntClass = "09"}.In(_db);

            new TmClass(countryCode, "10", "T") {GoodsOrService = "G", IntClass = "11"}.In(_db);

            new TmClass(countryCode, "90", "T") {GoodsOrService = "G", IntClass = "91"}.In(_db);

            new TmClass(countryCode, "90", "T") {GoodsOrService = "G", IntClass = "91"}.In(_db);

            return this;
        }
    }
}