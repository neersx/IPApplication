using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Web.Cases
{
    public class FileLocationsControllerFacts : FactBase
    {
        [Fact]
        public void ReturnsFileLocations()
        {
            var f = new FileLocationsControllerFixture(Db).WithCase(out var @case, out _).WithFileLocationsData(@case);
            var result = f.Subject.GetFileLocations(@case.Id, false, new CommonQueryParameters());

            Assert.NotNull(result);
            Assert.Equal(6, ((IEnumerable<FileLocationsData>)result.Data).ToArray().Length);
        }

        [Fact]
        public void ReturnsFileLocationHistory()
        {
            var f = new FileLocationsControllerFixture(Db).WithCase(out var @case, out _).WithFileLocationsData(@case, true);
            var result = f.Subject.GetFileLocations(@case.Id, true, new CommonQueryParameters());

            Assert.NotNull(result);
            Assert.Equal(6, ((IEnumerable<FileLocationsData>)result.Data).ToArray().Length);
        }

        [Fact]
        public void GetFileLocationForFilePart()
        {
            var f = new FileLocationsControllerFixture(Db).WithCase(out var @case, out var filePartId).GetFileLocationForFilePart(@case, filePartId);
            var result = f.Subject.GetFileLocationForFilePart(@case.Id, new CommonQueryParameters(), filePartId);

            Assert.NotNull(result);
            Assert.Equal(1, ((IEnumerable<FileLocationsData>)result.Data).ToArray().Length);
        }

        [Fact]
        public void ReturnsCaseIrn()
        {
            var f = new FileLocationsControllerFixture(Db).WithCase(out var @case, out _);
            f.Subject.GetCaseReference(@case.Id).Returns(@case.Irn);

            var result = f.Subject.GetCaseReference(@case.Id);

            Assert.NotNull(result);
            Assert.Equal(@case.Irn, result);
        }

        [Fact]
        public void ReturnsFileLocationHistoryWithPaging()
        {
            var queryParams = new CommonQueryParameters()
            {
                Skip = 1,
                Take = 3
            };
            var f = new FileLocationsControllerFixture(Db).WithCase(out var @case, out _).WithFileLocationsData(@case, true);
            var result = f.Subject.GetFileLocations(@case.Id, true, queryParams);

            Assert.NotNull(result);
            Assert.Equal(3, ((IEnumerable<FileLocationsData>)result.Data).ToArray().Length);
        }

        public class FileLocationsControllerFixture : IFixture<FileLocationsController>
        {
            public ICommonQueryService CommonQueryService { get; set; }
            readonly IFileLocations _fileLocations;
            readonly InMemoryDbContext _db;
            public FileLocationsControllerFixture(InMemoryDbContext db)
            {
                CommonQueryService = Substitute.For<ICommonQueryService>();
                CommonQueryService.Filter(Arg.Any<IEnumerable<FileLocationsData>>(), Arg.Any<CommonQueryParameters>())
                                  .Returns(x => x[0]);
                _fileLocations = Substitute.For<IFileLocations>();
                _db = db;
                Subject = new FileLocationsController(_fileLocations, CommonQueryService);
            }
            public FileLocationsController Subject { get; }

            public FileLocationsControllerFixture WithCase(out Case @case, out int filePart)
            {
                @case = new CaseBuilder().Build().In(_db);
                filePart = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(_db).FilePart;
                return this;
            }

            public FileLocationsControllerFixture WithFileLocationsData(Case @case, bool showHistory = false)
            {
                CommonQueryService = Substitute.For<ICommonQueryService>();
                var data = Enumerable.Range(1, 5).Select(_ => new FileLocationsData
                {
                    WhenMoved = Fixture.Date(),
                    BarCode = Fixture.String(),
                    BayNo = Fixture.String(),
                    FileLocation = Fixture.String(),
                    IssuedBy = Fixture.String(),
                    FileLocationId = Fixture.Integer(),
                    FilePart = Fixture.String(),

                }).ToList();

                data.Add(new FileLocationsData
                {
                    WhenMoved = Fixture.Date(),
                    BarCode = Fixture.String(),
                    BayNo = Fixture.String(),
                    FileLocation = Fixture.String(),
                    IssuedBy = Fixture.String(),
                    FileLocationId = Fixture.Integer(),
                    FilePart = Fixture.String()
                });
                _fileLocations.GetCaseFileLocations(@case.Id, null, showHistory).Returns(data.AsQueryable());
                return this;
            }

            public FileLocationsControllerFixture GetFileLocationForFilePart(Case @case, int filePartId)
            {
                CommonQueryService = Substitute.For<ICommonQueryService>();
                var data = Enumerable.Range(1, 1).Select(_ => new FileLocationsData
                {
                    WhenMoved = Fixture.Date(),
                    BarCode = Fixture.String(),
                    BayNo = Fixture.String(),
                    FileLocation = Fixture.String(),
                    IssuedBy = Fixture.String(),
                    FileLocationId = Fixture.Integer(),
                    FilePart = Fixture.String(),

                }).ToList();

                _fileLocations.GetCaseFileLocations(@case.Id, filePartId, false, true).Returns(data.AsQueryable());
                return this;
            }
        }
    }
}
