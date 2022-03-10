using System.IO;
using System.Linq;
using Xunit;

namespace Inprotech.Setup.Tests
{
    public class ValidationServiceFacts
    {
        public ValidationServiceFacts()
        {
            _validationService = new ValidationService();
        }

        readonly IValidationService _validationService;

        [Fact]
        public void ShouldReturnErrorForLocalPathWhenSharedPathIndicated()
        {
            var input = new FolderValidationInput
            {
                CurrentValue = Directory.GetCurrentDirectory(),
                ShouldUseSharedPath = true
            };

            var res = _validationService.ValidateFolder(input, out var validationErrors);
            Assert.False(res);
            Assert.Equal("Multi-node configuration requires the Storage Folder to be the same and accessible by all nodes", validationErrors.First());
        }

        [Fact]
        public void ShouldReturnErrorForNoFolder()
        {
            var res = _validationService.ValidateFolder(new FolderValidationInput(), out var validationErrors);
            Assert.False(res);
            Assert.Equal("Required", validationErrors.First());
        }

        [Fact]
        public void ShouldReturnErrorWhenCurrentValueIsSubDirectoryOfOriginalValue()
        {
            var current = new DirectoryInfo(Directory.GetCurrentDirectory());

            var input = new FolderValidationInput
            {
                OriginalValue = current.Parent.FullName,
                CurrentValue = current.FullName
            };

            var res = _validationService.ValidateFolder(input, out var validationErrors);
            Assert.False(res);
            Assert.Equal("Cannot change location to a subdirectory", validationErrors.First());
        }

        [Fact]
        public void ShouldReturnErrorWhenDirectoryDoesNotExist()
        {
            var input = new FolderValidationInput
            {
                CurrentValue = "abc"
            };

            var res = _validationService.ValidateFolder(input, out var validationErrors);
            Assert.False(res);
            Assert.Equal("The directory does not exist", validationErrors.First());
        }
    }
}