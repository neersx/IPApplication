using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using System.Linq;
using System.Web.Http;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class FilepartPicklistMaintenanceFacts
    {
        public class SaveMethod : FactBase
        {
            [Fact]
            public void AddFilePart()
            {
                var fixture = new FilepartPicklistMaintenanceFixture(Db);
                var model = new FilePartPicklistItem
                {
                    CaseId = 48,
                    Value = "File1",

                };
                var r = fixture.Subject.Save(model);
                var justAdded = Db.Set<CaseFilePart>().Last();
                Assert.Equal("success", r.Result);
                Assert.Equal(model.Value, justAdded.FilePartTitle);
            }

            [Fact]
            public void DeleteFilePart()
            {
                var fixture = new FilepartPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();
                var r = fixture.Subject.Delete(48);
                var filePart = Db.Set<CaseFilePart>().Where(gp => gp.FilePart == 48).ToArray();

                Assert.Equal("success", r.Result);
                Assert.Empty(filePart);
            }

            [Fact]
            public void UpdateFilePart()
            {
                var fixture = new FilepartPicklistMaintenanceFixture(Db);
                var model = new FilePartPicklistItem
                {
                    CaseId = 48,
                    Value = "File12",

                };
                fixture.SetupDbData();
                var r = fixture.Subject.Update(48, model);
                var filePart = Db.Set<CaseFilePart>().Where(gp => gp.FilePart == 48).FirstOrDefault();

                Assert.Equal("success", r.Result);
                if (filePart != null) Assert.Equal(model.Value, filePart.FilePartTitle);
            }

            [Fact]
            public void SearchFilePart()
            {
                var fixture = new FilepartPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();
                var r = fixture.Subject.Search(null, string.Empty, 48);
                var filePart = Db.Set<CaseFilePart>().ToArray();
                Assert.Equal(2, r.Data.Length);
                Assert.NotEqual(filePart.Count(), r.Data.Length);
            }

        }

        public class FetchRecod : FactBase
        {
            [Fact]
            public void GetFilePartByPassingId()
            {
                var fixture = new FilepartPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();
                var r = fixture.Subject.GetFile(2, 48);
                Assert.Equal(2, r.Key);
                Assert.Equal(48, r.CaseId);
                Assert.Equal("File2", r.Value);
            }

            [Fact]
            public void ThrowsExcepttionWhenRecordNotFound()
            {
                var fixture = new FilepartPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();
                var exception = Record.Exception(() => fixture.Subject.GetFile(Fixture.Short(), Fixture.Integer()));
                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class FilepartPicklistMaintenanceFixture : IFixture<FilePartPicklistMaintenance>
        {
            readonly InMemoryDbContext _db;

            public FilepartPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new FilePartPicklistMaintenance(_db);
            }
            public FilePartPicklistMaintenance Subject { get; set; }

            public void SetupDbData()
            {
                new CaseFilePart(48)
                {
                    FilePart = 48,
                    FilePartTitle = "File1"
                }.In(_db);

                new CaseFilePart(48)
                {
                    FilePart = 2,
                    FilePartTitle = "File2"
                }.In(_db);
                new CaseFilePart(49)
                {
                    FilePart = 23,
                    FilePartTitle = "File23"
                }.In(_db);
            }
        }
    }
}
