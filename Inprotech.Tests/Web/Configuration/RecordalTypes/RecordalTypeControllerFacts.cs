using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.RecordalType;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.RecordalTypes
{
    public class RecordalTypeControllerFixture : IFixture<RecordalTypeController>
    {
        public RecordalTypeControllerFixture()
        {
            RecordalTypes = Substitute.For<IRecordalTypes>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            Subject = new RecordalTypeController(RecordalTypes, TaskSecurityProvider);
        }
        public RecordalTypeController Subject { get; set; }

        public IRecordalTypes RecordalTypes { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
    }
    public class RecordalTypeControllerFacts : FactBase
    {
        [Fact]
        public void ShouldReturnTaskPermissions()
        {
            var f = new RecordalTypeControllerFixture();
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRecordalType, ApplicationTaskAccessLevel.Modify).Returns(true);
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRecordalType, ApplicationTaskAccessLevel.Delete).Returns(false);
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRecordalType, ApplicationTaskAccessLevel.Create).Returns(true);

            var result = f.Subject.ViewData();
            Assert.True(result.CanEdit);
            Assert.True(result.CanAdd);
            Assert.False(result.CanDelete);
        }

        [Fact]
        public async Task GetRecordalTypesShouldReturnAllRecordalTypes()
        {
            var f = new RecordalTypeControllerFixture();
            f.RecordalTypes.GetRecordalTypes().Returns(new List<RecordalTypeItems> {new RecordalTypeItems {Id = 1, RecordalType = "XYZ"}, new RecordalTypeItems {Id = 2, RecordalType = "ABC"}});
            var result = (await f.Subject.GetRecordalTypes(new SearchOptions(), new CommonQueryParameters())).ToArray();
            Assert.Equal(2, result.Length);
            Assert.Equal("ABC", result[0].RecordalType);
        }

        [Fact]
        public async Task GetRecordalTypesShouldReturnRecordalTypesBasedOnSearch()
        {
            var f = new RecordalTypeControllerFixture();
            f.RecordalTypes.GetRecordalTypes().Returns(new List<RecordalTypeItems> {new RecordalTypeItems {Id = 1, RecordalType = "XYZ"}, new RecordalTypeItems {Id = 2, RecordalType = "ABC"}});
            var result = (await f.Subject.GetRecordalTypes(new SearchOptions {Text="X"}, new CommonQueryParameters())).ToArray();
            Assert.Equal(1, result.Length);
            Assert.Equal("XYZ", result[0].RecordalType);
        }

        [Fact]
        public async Task DeleteShouldCallDeleteRecordalTypes()
        {
            var f = new RecordalTypeControllerFixture();
            await f.Subject.DeleteRecordalType(Fixture.Integer());
            await f.RecordalTypes.Received(1).Delete(Arg.Any<int>());
        }

        [Fact]
        public async Task GetRecordalTypeFormShouldCallRecordalTypeGet()
        {
            var f = new RecordalTypeControllerFixture();
            await f.Subject.GetRecordalTypeFormById(Fixture.Integer());
            await f.RecordalTypes.Received(1).GetRecordalTypeForm(Arg.Any<int>());
        }

        [Fact]
        public async Task GetAllElementsShouldCallRecordalTypeGetElements()
        {
            var f = new RecordalTypeControllerFixture();
            await f.Subject.GetAllElements();
            await f.RecordalTypes.Received(1).GetAllElements();
        }

        [Fact]
        public async Task GetRecordalElementShouldCallRecordalTypeElement()
        {
            var f = new RecordalTypeControllerFixture();
            await f.Subject.GetRecordalElementFormById(Fixture.Integer());
            await f.RecordalTypes.Received(1).GetRecordalElementForm(Arg.Any<int>());
        }
    }
}
