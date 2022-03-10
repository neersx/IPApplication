using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http.Results;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Configuration.FileLocationOffice;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration
{
    public class FileLocationOfficeControllerFacts
    {
        public class FileLocationOfficeControllerFixture : IFixture<FileLocationOfficeController>
        {
            public FileLocationOfficeControllerFixture(InMemoryDbContext db)
            {
                CultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new FileLocationOfficeController(db, CultureResolver);
                CommonQueryParameters = CommonQueryParameters.Default;
                CommonQueryParameters.SortBy = null;
                CommonQueryParameters.SortDir = null;
            }

            public IPreferredCultureResolver CultureResolver { get; set; }
            public CommonQueryParameters CommonQueryParameters { get; set; }
            public FileLocationOfficeController Subject { get; set; }
        }

        public class GetFileLocationOffice : FactBase
        {
            [Fact]
            public async Task ReturnsAllOffices()
            {
                var t1 = new TableCodeBuilder {TableType = (short) TableTypes.FileLocation, Description = Fixture.String("XYZ")}.Build().In(Db);
                var t2 =new TableCodeBuilder {TableType = (short) TableTypes.FileLocation, Description = Fixture.String("ABC")}.Build().In(Db);
                var t3 =new TableCodeBuilder {TableType = (short) TableTypes.FileLocation, Description = Fixture.String("FVC")}.Build().In(Db);
                var o1 = new OfficeBuilder().Build().In(Db);
                new InprotechKaizen.Model.Cases.FileLocationOffice(t1, o1).In(Db);

                var f = new FileLocationOfficeControllerFixture(Db);
                var r = await f.Subject.GetFileLocationOffices(f.CommonQueryParameters);
                var results = r.ToArray();

                Assert.Equal(3, results.Length);
                Assert.Equal(t2.Id, results[0].Id);
                Assert.Null(results[0].Office);
                Assert.Equal(t3.Id, results[1].Id);
                Assert.Null(results[1].Office);
                Assert.Equal(t1.Id, results[2].Id);
                Assert.Equal(o1.Id, results[2].Office.Key);
            }
        }

        public class UpdateFileLocationOffice : FactBase
        {
            [Fact]
            public async Task ShouldThrowArgumentNullException()
            {
                var f = new FileLocationOfficeControllerFixture(Db);
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.UpdateFileLocationOffice(null);
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldUpdateFileLocationOffice()
            {
                var f = new FileLocationOfficeControllerFixture(Db);
                var t1 = new TableCodeBuilder {TableType = (short) TableTypes.FileLocation, Description = Fixture.String("XYZ")}.Build().In(Db);
                var t2 =new TableCodeBuilder {TableType = (short) TableTypes.FileLocation, Description = Fixture.String("ABC")}.Build().In(Db);
                var t3 =new TableCodeBuilder {TableType = (short) TableTypes.FileLocation, Description = Fixture.String("FVC")}.Build().In(Db);
                var o1 = new OfficeBuilder().Build().In(Db);
                var o2 = new OfficeBuilder().Build().In(Db);
                new InprotechKaizen.Model.Cases.FileLocationOffice(t1, o1).In(Db);
                new InprotechKaizen.Model.Cases.FileLocationOffice(t2, o1).In(Db);

                var model = new FileLocationOfficeRequest
                {
                    Rows = new List<FileLocationOffice>
                    {
                        new FileLocationOffice {Id = t1.Id, Office = new Office {Key = o2.Id}},
                        new FileLocationOffice {Id = t3.Id, Office = new Office {Key = o1.Id}},
                        new FileLocationOffice {Id = t2.Id, Office = null}
                    }
                };

                await f.Subject.UpdateFileLocationOffice(model);
                var fileLocationOffice = Db.Set<InprotechKaizen.Model.Cases.FileLocationOffice>().FirstOrDefault(_ => _.FileLocationId == t1.Id);
                Assert.NotNull(fileLocationOffice);
                Assert.Equal(o2.Id, fileLocationOffice.OfficeId);
                var fileLocationOffice2 = Db.Set<InprotechKaizen.Model.Cases.FileLocationOffice>().FirstOrDefault(_ => _.FileLocationId == t3.Id);
                Assert.NotNull(fileLocationOffice2);
                Assert.Equal(o1.Id, fileLocationOffice2.OfficeId);
                var fileLocationOffice3 = Db.Set<InprotechKaizen.Model.Cases.FileLocationOffice>().FirstOrDefault(_ => _.FileLocationId == t2.Id);
                Assert.Null(fileLocationOffice3);
            }
        }
    }
}
