using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration.Component.iManage
{
    public class FolderTypeMapFacts
    {
        [Fact]
        public void ShouldReturnEmailIfEmailSupplied()
        {
            var result = FolderTypeMap.Map(Fixture.String(), Fixture.String());
            
            Assert.Equal(FolderType.EmailFolder, result);
        }

        [Theory]
        [InlineData("tab", FolderType.Tab)]
        [InlineData("search", FolderType.SearchFolder)]
        [InlineData("regular", FolderType.Folder)]
        [InlineData("other", FolderType.NotSet)]
        [InlineData("another", FolderType.NotSet)]
        public void ShouldReturnExpectedFolderTypeForInput(string input, FolderType expectedType)
        {
            var result = FolderTypeMap.Map(input, string.Empty);
            
            Assert.Equal(expectedType, result);
        }
    }
}
