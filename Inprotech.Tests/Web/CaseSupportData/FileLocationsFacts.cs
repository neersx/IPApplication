using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Cases.Maintenance;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class FileLocationsFacts
    {
        public class FileLocationsMethod : FactBase
        {
            dynamic SetupData()
            {
                var @case = new CaseBuilder
                {
                    Country = new CountryBuilder { Id = "ZZZ" }.Build().In(Db),
                    CaseType = new CaseTypeBuilder { Id = "A" }.Build().In(Db),
                    PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(Db)
                }.Build().In(Db);

                var fileLocation1 = new TableCode { TableTypeId = (int)TableTypes.FileLocation, Name = Fixture.String() };

                var fileLocation2 = new TableCode { TableTypeId = (int)TableTypes.FileLocation, Name = Fixture.String() };

                var filePart1 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);

                var filePart2 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);

                var filePart3 = new CaseFilePart(@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);

                var caseLocation1 = new CaseLocation(@case, fileLocation1, DateTime.Now.AddDays(-2)) { BayNo = Fixture.String(), FilePartId = filePart1.FilePart }.In(Db);
                @case.CaseLocations.Add(caseLocation1);

                var caseLocation2 = new CaseLocation(@case, fileLocation1, DateTime.Now.AddDays(-1)) { BayNo = Fixture.String(), FilePartId = filePart2.FilePart }.In(Db);
                @case.CaseLocations.Add(caseLocation2);

                var caseLocation3 = new CaseLocation(@case, fileLocation2, DateTime.Now) { BayNo = Fixture.String(), FilePartId = filePart3.FilePart }.In(Db);
                @case.CaseLocations.Add(caseLocation3);

                var fileLocation = new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db);
                var fileRequest = new FileRequest
                {
                    CaseId = @case.Id,
                    FileLocationId = fileLocation.Id,
                    FilePartId = filePart1.FilePart,
                    DateRequired = caseLocation1.WhenMoved.AddDays(-1),
                    Status = 0,
                    SequenceNo = Fixture.Short()
                }.In(Db);

                @case.FileRequests.Add(fileRequest);

                return new
                {
                    caseLocation1,
                    caseLocation2,
                    caseLocation3,
                    filePart1,
                    filePart2,
                    @case
                };
            }

            [Fact]
            public void ReturnsFileLocationForFilePart()
            {
                var f = new FileLocationsFixture(Db);
                var data = SetupData();

                if (!(data.@case is Case @case)) return;
                var r = f.Subject.GetCaseFileLocations(@case.Id, data.filePart1.FilePart, false, true);
                var a = ((IEnumerable<FileLocationsData>)r).ToArray();
                Assert.Equal(a.Length, 1);
                Assert.Equal(data.caseLocation1.BayNo, a[0].BayNo);
                Assert.Equal(data.caseLocation1.FileLocation.Name, a[0].FileLocation);
                Assert.Equal(data.caseLocation1.WhenMoved, a[0].WhenMoved);
                Assert.Equal(data.caseLocation1.BayNo, a[0].BayNo);
            }

            [Fact]
            public void ReturnsNoMatchingFileLocationForFilePart()
            {
                var f = new FileLocationsFixture(Db);
                var data = SetupData();
                var filePart = new CaseFilePart(data.@case.Id) { FilePart = Fixture.Short(), FilePartTitle = Fixture.String() }.In(Db);

                if (!(data.@case is Case @case)) return;
                var r = f.Subject.GetCaseFileLocations(@case.Id, filePart.FilePart, false, true);
                var a = r.ToArray();
                Assert.Equal(a.Length, 0);
            }

            [Fact]
            public void ReturnsFileLocationDataInDescendingOrder()
            {
                var f = new FileLocationsFixture(Db);
                var data = SetupData();

                if (!(data.@case is Case @case)) return;
                var r = f.Subject.GetCaseFileLocations(@case.Id, 0, false, false);
                var a = r.ToArray();
                Assert.Equal(a.Length, 3);
                Assert.Equal(data.caseLocation3.BayNo, a[0].BayNo);
                Assert.Equal(data.caseLocation3.FileLocation.Name, a[0].FileLocation);
                Assert.Equal(data.caseLocation3.WhenMoved, a[0].WhenMoved);
                Assert.Equal(data.caseLocation2.BayNo, a[1].BayNo);
                Assert.Equal(data.caseLocation2.FileLocation.Name, a[1].FileLocation);
                Assert.Equal(data.filePart2.FilePartTitle, a[1].FilePart);
                Assert.Equal(data.caseLocation2.WhenMoved, a[1].WhenMoved);
                Assert.Equal(data.caseLocation1.BayNo, a[2].BayNo);
                Assert.Equal(data.caseLocation1.FileLocation.Name, a[2].FileLocation);
                Assert.Equal(data.filePart1.FilePartTitle, a[2].FilePart);
                Assert.Equal(data.caseLocation1.WhenMoved, a[2].WhenMoved);
            }

            [Fact]
            public void ReturnsNoElementData()
            {
                var f = new FileLocationsFixture(Db);
                var r = f.Subject.GetCaseFileLocations(000, 0, false, false);
                var a = r.ToArray();
                Assert.Null(a.FirstOrDefault());
            }

            [Fact]
            public void ReturnsOnlyUniqueFilePartLocation()
            {
                var f = new FileLocationsFixture(Db);
                var data = SetupData();

                if (!(data.@case is Case @case)) return;

                data.caseLocation3.FilePartId = data.filePart1.FilePart;

                var r = f.Subject.GetCaseFileLocations(@case.Id, 0, false, false);
                var a = r.ToArray();
                Assert.Equal(a.Length, 2);
                Assert.Equal(data.caseLocation3.BayNo, a[0].BayNo);
                Assert.Equal(data.caseLocation3.FileLocation.Name, a[0].FileLocation);
                Assert.Equal(data.caseLocation3.WhenMoved, a[0].WhenMoved);
                Assert.Equal(data.caseLocation2.BayNo, a[1].BayNo);
                Assert.Equal(data.caseLocation2.FileLocation.Name, a[1].FileLocation);
                Assert.Equal(data.filePart2.FilePartTitle, a[1].FilePart);
                Assert.Equal(data.caseLocation2.WhenMoved, a[1].WhenMoved);
            }

            [Fact]
            public void ReturnNoErrorWhenNoDuplicateCombinationExists()
            {
                var f = new FileLocationsFixture(Db);
                var data = SetupData();

                var changedRows = new FileLocationsData[] { };

                var newRow = new FileLocationsData
                {
                    FileLocationId = data.caseLocation1.FileLocationId,
                    WhenMoved = Fixture.Date(),
                    FilePartId = Fixture.Short(),
                    RowKey = "0"
                };

                var validationErrors = f.Subject.ValidateFileLocations((Case)data.@case, newRow, changedRows).ToArray();
                Assert.Equal(0, validationErrors.Length);
            }

            [Fact]
            public void ReturnErrorWhenDuplicateCombinationExists()
            {
                var f = new FileLocationsFixture(Db);
                var data = SetupData();

                var changedRows = new FileLocationsData[] { };

                var newRow = new FileLocationsData
                {
                    FileLocationId = data.caseLocation1.FileLocationId,
                    WhenMoved = data.caseLocation1.WhenMoved,
                    FilePartId = data.filePart1.FilePart,
                    RowKey = "0"
                };

                var validationErrors = f.Subject.ValidateFileLocations((Case)data.@case, newRow, changedRows).ToArray();
                Assert.Equal(1, validationErrors.Length);
                Assert.Equal(KnownCaseMaintenanceTopics.FileLocations, validationErrors[0].Topic);
                Assert.Equal(FileLocationsInputNames.FileLocation, validationErrors[0].Field);
                Assert.Equal(newRow.RowKey, validationErrors[0].Id);
            }

            [Fact]
            public void ReturnCaseIrn()
            {
                var f = new FileLocationsFixture(Db);
                var data = SetupData();

                var irn = f.Subject.GetCaseReference(data.@case.Id);
                Assert.Equal(irn, data.@case.Irn);
            }

            [Fact]
            public void ReturnErrorWhenFilePartExistOnFileRequest()
            {
                var f = new FileLocationsFixture(Db);
                var data = SetupData();

                var changedRows = new FileLocationsData[] { };

                var newRow = new FileLocationsData
                {
                    FileLocationId = data.caseLocation1.FileLocationId,
                    WhenMoved = data.caseLocation1.WhenMoved.AddDays(1),
                    FilePartId = data.filePart1.FilePart,
                    RowKey = "0"
                };

                var validationErrors = f.Subject.ValidateFileLocations((Case)data.@case, newRow, changedRows).ToArray();
                Assert.Equal(1, validationErrors.Length);
                Assert.Equal(KnownCaseMaintenanceTopics.FileLocations, validationErrors[0].Topic);
                Assert.Equal(FileLocationsInputNames.ActiveFileRequest, validationErrors[0].Field);
            }

            [Fact]
            public void ReturnDuplicateErrorEvenWhenFilePartExistOnFileRequest()
            {
                var f = new FileLocationsFixture(Db);
                var data = SetupData();

                var changedRows = new FileLocationsData[] { };

                var newRow = new FileLocationsData
                {
                    FileLocationId = data.caseLocation1.FileLocationId,
                    WhenMoved = data.caseLocation1.WhenMoved.AddDays(10),
                    FilePartId = data.filePart1.FilePart,
                    RowKey = "0"
                };

                var validationErrors = f.Subject.ValidateFileLocations((Case)data.@case, newRow, changedRows).ToArray();
                Assert.Equal(1, validationErrors.Length);
                Assert.Equal(KnownCaseMaintenanceTopics.FileLocations, validationErrors[0].Topic);
                Assert.Equal(FileLocationsInputNames.ActiveFileRequest, validationErrors[0].Field);
            }
        }

        public class FileLocationsFixture : IFixture<FileLocations>
        {
            public FileLocationsFixture(InMemoryDbContext db)
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new FileLocations(db, cultureResolver);
            }

            public FileLocations Subject { get; }
        }
    }
}