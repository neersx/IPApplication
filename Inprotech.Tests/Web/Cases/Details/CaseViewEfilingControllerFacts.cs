using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases.Filing.Electronic;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseViewEfilingControllerFacts
    {
        public class GetPackages : FactBase
        {
            [Theory]
            [InlineData("PackageReference", "asc", "abc001", "abc003")]
            [InlineData("PackageReference", "desc", "abc003", "abc001")]
            [InlineData("LastStatusChange", "asc", "abc002", "abc003")]
            [InlineData("LastStatusChange", "desc", "abc003", "abc002")]
            public void ReturnsSortedResultsFromPackageDetailsStoredProcedure(string sortBy, string sortDir, string expectedFirst, string expectedLast)
            {
                var futureDate = Fixture.FutureDate();
                var qp = CommonQueryParameters.Default;
                qp.SortBy = sortBy;
                qp.SortDir = sortDir;

                var package1 = new EfilingPackageListItem {PackageReference = "abc001", PackageType = Fixture.String("package"), LastStatusChange = futureDate};
                var package2 = new EfilingPackageListItem {PackageReference = "abc002", PackageType = Fixture.String("package"), LastStatusChange = Fixture.PastDate()};
                var package3 = new EfilingPackageListItem {PackageReference = "abc003", PackageType = Fixture.String("package"), LastStatusChange = futureDate.AddDays(1)};
                var caseKeys = string.Join(",", Fixture.Integer(), Fixture.Integer(), Fixture.Integer(), Fixture.Integer());

                var f = new CaseViewEfilingControllerFixture();
                f.EFilingCompatibility.Status.Returns(true);
                f.CaseViewEfiling.GetPackages(Arg.Any<string>())
                 .Returns(new List<EfilingPackageListItem>
                 {
                     package2,
                     package3,
                     package1
                 });
                f.SubjectSecurity.HasAccessToSubject(Arg.Any<ApplicationSubject>()).Returns(true);

                var r = f.Subject.GetPackage(caseKeys, qp);
                f.CaseViewEfiling.Received(1).GetPackages(caseKeys);
                Assert.Equal(3, r.Data.Count());
                Assert.Equal(expectedFirst, ((EfilingPackageListItem) r.Data.First()).PackageReference);
                Assert.Equal(expectedLast, ((EfilingPackageListItem) r.Data.Last()).PackageReference);
            }

            [Fact]
            public void ReturnsEmptyPageResultsWhenNoPermissionsToSubject()
            {
                var f = new CaseViewEfilingControllerFixture();
                f.EFilingCompatibility.Status.Returns(true);

                var r = f.Subject.GetPackage("1,2,3,4,a,b,c", CommonQueryParameters.Default);
                Assert.Null(r.Data);
                Assert.Equal(0, r.Pagination.Total);
            }

            [Fact]
            public void ReturnsEmptyPageResultsWhenStoredProcedureDoesNotExist()
            {
                var f = new CaseViewEfilingControllerFixture();
                f.EFilingCompatibility.Status.Returns(false);

                var r = f.Subject.GetPackage("1,2,3,4,a,b,c", CommonQueryParameters.Default);
                Assert.Null(r.Data);
                Assert.Equal(0, r.Pagination.Total);
            }

            [Fact]
            public void ReturnsHistory()
            {
                var f = new CaseViewEfilingControllerFixture();
                f.EFilingCompatibility.Status.Returns(true);
                f.SubjectSecurity.HasAccessToSubject(Arg.Any<ApplicationSubject>()).Returns(true);
                var qp = CommonQueryParameters.Default;
                qp.SortBy = "StatusDateTime";
                qp.SortDir = "desc";

                var history1 = new EfilingHistoryDataItem { Status = Fixture.String(), StatusDateTime = DateTime.Today, StatusDescription = Fixture.String() };
                var history2 = new EfilingHistoryDataItem { Status = Fixture.String(), StatusDateTime = DateTime.Today.AddDays(-1), StatusDescription = Fixture.String() };
                var history3 = new EfilingHistoryDataItem { Status = Fixture.String(), StatusDateTime = DateTime.Today.AddDays(-2), StatusDescription = Fixture.String() };

                var exchangeId = Fixture.Integer();
                f.CaseViewEfiling.GetPackageHistory(Arg.Any<int>()).Returns(new List<EfilingHistoryDataItem> { history1, history2, history3 });
                var results = f.Subject.GetPackageHistory(Fixture.Integer(), qp, exchangeId);
                f.CaseViewEfiling.Received(1).GetPackageHistory(exchangeId);
                Assert.Equal(3, results.Data.Count());
                Assert.Equal(history1.Status, ((EfilingHistoryDataItem)results.Data.First()).Status);
                Assert.Equal(history3.Status, ((EfilingHistoryDataItem)results.Data.Last()).Status);
            }
        }

        public class GetPackageFiles : FactBase
        {
            [Fact]
            public void ThrowExceptionWhenNoPermissionsToSubject()
            {
                var f = new CaseViewEfilingControllerFixture();
                f.EFilingCompatibility.Status.Returns(true);
                f.SubjectSecurity.HasAccessToSubject(Arg.Any<ApplicationSubject>()).Returns(false);

                var packageFilter = new CaseViewEfilingController.PackageFilesQuery
                {
                    ExchangeId = 1,
                    PackageSequence = 1
                };

                Assert.Throws<UnauthorizedAccessException>(() => f.Subject.GetPackageFiles(1, packageFilter));
            }

            [Fact]
            public void ThrowExceptionWhenStoredProcedureDoesNotExist()
            {
                var f = new CaseViewEfilingControllerFixture();
                f.EFilingCompatibility.Status.Returns(false);

                var packageFilter = new CaseViewEfilingController.PackageFilesQuery
                {
                    ExchangeId = 1,
                    PackageSequence = 1
                };
                Assert.Throws<ConfigurationErrorsException>(() => f.Subject.GetPackageFiles(1, packageFilter));
            }

            [Fact]
            public void ReturnsResultFromPackageFilesStoredProcedure()
            {
                var f = new CaseViewEfilingControllerFixture();
                f.EFilingCompatibility.Status.Returns(true);
                f.SubjectSecurity.HasAccessToSubject(Arg.Any<ApplicationSubject>()).Returns(true);

                var packageFilter = new CaseViewEfilingController.PackageFilesQuery
                {
                    ExchangeId = 1,
                    PackageSequence = 1
                };

                var file1 = new EfilingPackageFilesListItem {ComponentDescription = Fixture.String(), FileName = Fixture.String("AAA"), FileSize = null, FileType = Fixture.String(), Outbound = 1};
                var file2 = new EfilingPackageFilesListItem {ComponentDescription = Fixture.String(), FileName = Fixture.String("BBB"), FileSize = Fixture.Integer(), FileType = Fixture.String(), Outbound = 1};
                var file3 = new EfilingPackageFilesListItem {ComponentDescription = Fixture.String(), FileName = Fixture.String("CCC"), FileSize = Fixture.Integer(), FileType = Fixture.String(), Outbound = 0};

                f.CaseViewEfiling.GetPackageFiles(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int>()).Returns(new List<EfilingPackageFilesListItem> {file1, file2, file3});

                var r = f.Subject.GetPackageFiles(1, packageFilter);
                f.CaseViewEfiling.Received(1).GetPackageFiles(1, packageFilter.ExchangeId, packageFilter.PackageSequence);
                Assert.Equal(3, r.Length);
            }

            [Fact]
            public void ReturnsFileDataAndStatusOk()
            {
                var f = new CaseViewEfilingControllerFixture();
                f.EFilingCompatibility.Status.Returns(true);
                f.SubjectSecurity.HasAccessToSubject(Arg.Any<ApplicationSubject>()).Returns(true);

                var packageFileDataFilter = new CaseViewEfilingController.PackageFileDataQuery
                {
                    ExchangeId = 1,
                    PackageSequence = 2,
                    PackageFileSequence = 2
                };

                var zipData = new EfilingFileDataItem {FileData = Fixture.RandomBytes(100), FileName =Fixture.RandomString(10), FileType = KnownFileExtensions.Mpx};
                Stream fileData = new MemoryStream(Fixture.RandomBytes(50));

                f.CaseViewEfiling.GetPackageFileData(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int>()).Returns(zipData);
                f.EfilingFileViewer.OpenFileFromZip(zipData.FileData, zipData.FileName).Returns(fileData);
                var r = f.Subject.GetPackageFileData(1, packageFileDataFilter);
                f.CaseViewEfiling.Received(1).GetPackageFileData(1, packageFileDataFilter.PackageSequence, packageFileDataFilter.PackageFileSequence, packageFileDataFilter.ExchangeId);
                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            }

            [Fact]
            public void ReturnsDataNotFoundInZip()
            {
                var f = new CaseViewEfilingControllerFixture();
                f.EFilingCompatibility.Status.Returns(true);
                f.SubjectSecurity.HasAccessToSubject(Arg.Any<ApplicationSubject>()).Returns(true);

                var packageFileDataFilter = new CaseViewEfilingController.PackageFileDataQuery
                {
                    ExchangeId = 1,
                    PackageSequence = 2,
                    PackageFileSequence = 2
                };

                var zipData = new EfilingFileDataItem { FileData = Fixture.RandomBytes(100), FileName = Fixture.RandomString(10), FileType = KnownFileExtensions.Mpx };

                f.CaseViewEfiling.GetPackageFileData(Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<int?>()).Returns(zipData);
                f.EfilingFileViewer.OpenFileFromZip(zipData.FileData, zipData.FileName).Returns((Stream) null);
                var r = f.Subject.GetPackageFileData(1, packageFileDataFilter);
                f.CaseViewEfiling.Received(1).GetPackageFileData(1, packageFileDataFilter.PackageSequence, packageFileDataFilter.PackageFileSequence, packageFileDataFilter.ExchangeId);
                Assert.Equal(HttpStatusCode.NotFound, r.StatusCode);
            }

            [Fact]
            public void ReturnsDataNotFoundZipNotAvailable()
            {
                var f = new CaseViewEfilingControllerFixture();
                f.EFilingCompatibility.Status.Returns(true);
                f.SubjectSecurity.HasAccessToSubject(Arg.Any<ApplicationSubject>()).Returns(true);

                var packageFileDataFilter = new CaseViewEfilingController.PackageFileDataQuery
                {
                    ExchangeId = 1,
                    PackageSequence = 2,
                    PackageFileSequence = 2
                };

                f.CaseViewEfiling.GetPackageFileData(Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<int?>()).Returns((EfilingFileDataItem) null);
                var r = f.Subject.GetPackageFileData(1, packageFileDataFilter);
                f.CaseViewEfiling.Received(1).GetPackageFileData(1, packageFileDataFilter.PackageSequence, packageFileDataFilter.PackageFileSequence, packageFileDataFilter.ExchangeId);
                Assert.Equal(HttpStatusCode.NotFound, r.StatusCode);
            }
        }

        public class CaseViewEfilingControllerFixture : IFixture<CaseViewEfilingController>
        {
            public ICaseViewEfiling CaseViewEfiling { get; set; }
            public ISubjectSecurityProvider SubjectSecurity { get; set; }
            public IEFilingCompatibility EFilingCompatibility { get; set; }
            public CaseViewEfilingController Subject { get; set; }
            public IEfilingFileViewer EfilingFileViewer { get; set; }
            public const string RequestUrl = "http://www.abc.com/apps";

            public CaseViewEfilingControllerFixture()
            {
                CaseViewEfiling = Substitute.For<ICaseViewEfiling>();
                SubjectSecurity = Substitute.For<ISubjectSecurityProvider>();
                EFilingCompatibility = Substitute.For<IEFilingCompatibility>();
                EfilingFileViewer = Substitute.For<IEfilingFileViewer>();
                Subject = new CaseViewEfilingController(CaseViewEfiling, SubjectSecurity, EFilingCompatibility, EfilingFileViewer)
                {
                    Request = new HttpRequestMessage(HttpMethod.Get, RequestUrl)
                };
            }
        }
    }
}