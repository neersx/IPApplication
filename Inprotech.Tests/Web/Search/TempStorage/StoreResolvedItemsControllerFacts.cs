using System.Threading.Tasks;
using Inprotech.Web.Search.TempStorage;
using InprotechKaizen.Model.Components.System.Utilities;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TempStorage
{
    public class StoreResolvedItemsControllerFacts : FactBase
    {
        [Fact]
        public async Task ShouldAddAndReturnTempStorageId()
        {
            var tempStorageHandler = Substitute.For<ITempStorageHandler>();
            tempStorageHandler.Add(Arg.Any<string>()).Returns(1);

            var request = new StoreResolvedItemsRequest {Items = "1,2,3"};

            var subject = new StoreResolvedItemsController(tempStorageHandler);

            var result = await subject.Add(request);

            Assert.NotNull(result);
            Assert.Equal(result, 1);
        }
    }
}