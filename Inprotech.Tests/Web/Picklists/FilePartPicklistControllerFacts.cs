using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using NSubstitute;
using System;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class FilePartPicklistControllerFacts : FactBase
    {
        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsUpdateMaintenanceResponse()
            {
                var f = new FilePartPicklistControllerFixture();
                var mockResponse = new
                {
                    Result = "success",
                    Key = 48
                };
                var request = new FilePartPicklistItem { CaseId = 48, Key = 1, Value = "File12" };
                f.FilePartPicklistMaintenance.Update(Convert.ToInt16(request.Key), request).ReturnsForAnyArgs(mockResponse);
                var result = f.Subject.Update(Convert.ToInt16(request.Key), request);
                Assert.Equal("success", result.Result);
                Assert.Equal(48, result.Key);
            }

            [Fact]
            public void GetFileMethodResponse()
            {
                var f = new FilePartPicklistControllerFixture();
                var mockResponse = new FilePartPicklistItem
                {
                    Key = 1,
                    Value = "file1",
                    CaseId = -487
                };
                f.FilePartPicklistMaintenance.GetFile(1, -487).ReturnsForAnyArgs(mockResponse);
                var result = f.Subject.GetFile(1, -487);
                Assert.Equal("file1", result.Value);
                Assert.Equal(-487, result.CaseId);
            }

            [Fact]
            public void CallsFilePartMaintenanceGetFilePartponse()
            {
                var f = new FilePartPicklistControllerFixture();
                var mockResponse = new
                {
                    Result = "success"
                };
                f.FilePartPicklistMaintenance.Delete(42).ReturnsForAnyArgs(mockResponse);
                var result = f.Subject.Delete(1);

                Assert.Equal("success", result.Result);
            }
        }
        public class FilePartPicklistControllerFixture : IFixture<FilePartPicklistController>
        {
            public ICommonQueryService CommonQueryService { get; set; }
            public FilePartPicklistControllerFixture()
            {

                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                FilePartPicklistMaintenance = Substitute.For<IFilePartPicklistMaintenance>();

                Subject = new FilePartPicklistController(PreferredCultureResolver, FilePartPicklistMaintenance);
            }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public FilePartPicklistController Subject { get; }

            public IFilePartPicklistMaintenance FilePartPicklistMaintenance { get; set; }

        }
    }
}
