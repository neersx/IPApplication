using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.TempStorage;
using Newtonsoft.Json;
using Xunit;

namespace Inprotech.Tests.Model.Components.System.Utilities
{
    public class TempStorageHandlerFacts
    {
        public class AddMethod : FactBase
        {
            [Fact]
            public async Task ShouldAddStringsDirectly()
            {
                const string item = "1,2";

                var subject = new TempStorageHandler(Db);
                var tempStorageId = await subject.Add(item);

                Assert.NotEqual(-1, tempStorageId);

                var tempStorageItem = Db.Set<TempStorage>().SingleOrDefault(_ => _.Id == tempStorageId);

                Assert.NotNull(tempStorageItem);
                Assert.Equal(item, tempStorageItem.Value);
            }

            [Fact]
            public async Task ShouldSerialiseOtherTypesBeforeAdd()
            {
                var complexObject = new TestStructure
                {
                    A = Fixture.String(),
                    B = new InnerStructure
                    {
                        One = Fixture.Integer()
                    },
                    C = Fixture.Integer()
                };

                var subject = new TempStorageHandler(Db);
                var tempStorageId = await subject.Add(complexObject);

                Assert.NotEqual(-1, tempStorageId);

                var tempStorageItem = Db.Set<TempStorage>().SingleOrDefault(_ => _.Id == tempStorageId);

                Assert.NotNull(tempStorageItem);
                Assert.Equal(JsonConvert.SerializeObject(complexObject), tempStorageItem.Value);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public async Task ShouldDelete()
            {
                var tempStorageItem = new TempStorage("1,2").In(Db);

                var subject = new TempStorageHandler(Db);
                await subject.Remove(tempStorageItem.Id);

                var data = Db.Set<TempStorage>().SingleOrDefault(_ => _.Id == tempStorageItem.Id);
                Assert.Null(data);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public async Task ShouldGetStringsDirectly()
            {
                var tempStorageItem = new TempStorage("1,2").In(Db);

                var subject = new TempStorageHandler(Db);

                var result = await subject.Get<string>(tempStorageItem.Id);

                Assert.Equal(result, tempStorageItem.Value);
            }

            [Fact]
            public async Task ShouldDeserialiseValueWhenGettingOtherTypes()
            {
                var complexObject = new TestStructure
                {
                    A = Fixture.String(),
                    B = new InnerStructure
                    {
                        One = Fixture.Integer()
                    },
                    C = Fixture.Integer()
                };

                var tempStorageItem = new TempStorage(JsonConvert.SerializeObject(complexObject)).In(Db);

                var subject = new TempStorageHandler(Db);

                var result = await subject.Get<TestStructure>(tempStorageItem.Id);

                Assert.Equal(complexObject.A, result.A);
                Assert.Equal(complexObject.B.One, result.B.One);
                Assert.Equal(complexObject.C, result.C);
            }
        }

        public class PopMethod : FactBase
        {
            [Fact]
            public async Task ShouldGetStringsDirectlyThenDeleteFromTempStorage()
            {
                var tempStorageItem = new TempStorage("1,2").In(Db);

                var subject = new TempStorageHandler(Db);

                Assert.NotEmpty(Db.Set<TempStorage>());

                var result = await subject.Pop<string>(tempStorageItem.Id);

                Assert.Equal(result, tempStorageItem.Value);

                Assert.Empty(Db.Set<TempStorage>());
            }

            [Fact]
            public async Task ShouldDeserialiseValueWhenGettingOtherTypesThenDeleteFromTempStorage()
            {
                var complexObject = new TestStructure
                {
                    A = Fixture.String(),
                    B = new InnerStructure
                    {
                        One = Fixture.Integer()
                    },
                    C = Fixture.Integer()
                };

                var tempStorageItem = new TempStorage(JsonConvert.SerializeObject(complexObject)).In(Db);

                var subject = new TempStorageHandler(Db);

                Assert.NotEmpty(Db.Set<TempStorage>());

                var result = await subject.Pop<TestStructure>(tempStorageItem.Id);

                Assert.Equal(complexObject.A, result.A);
                Assert.Equal(complexObject.B.One, result.B.One);
                Assert.Equal(complexObject.C, result.C);

                Assert.Empty(Db.Set<TempStorage>());
            }
        }

        public class TestStructure
        {
            public string A { get; set; }

            public InnerStructure B { get; set; }

            public int C { get; set; }
        }

        public class InnerStructure
        {
            public int One { get; set; }
        }
    }
}