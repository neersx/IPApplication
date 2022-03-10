using System.IO;
using Inprotech.Setup.Core;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class FileSystemFacts
    {
        public class GetSafeFolderNameMethod
        {
            [Fact]
            public void ShouldNotContainAnyDirectorySeparators()
            {
                foreach (var invalid in new[]
                {
                    Path.AltDirectorySeparatorChar,
                    Path.DirectorySeparatorChar
                })
                {
                    var invalidFolderName = $"something_{invalid}_valid";

                    Assert.Equal("something__valid", new FileSystem().GetSafeFolderName(invalidFolderName));
                }
            }

            [Fact]
            public void ShouldNotContainAnyInvalidPathChars()
            {
                foreach (var invalid in Path.GetInvalidPathChars())
                {
                    var invalidFolderName = $"something_{invalid}_valid";

                    Assert.Equal("something__valid", new FileSystem().GetSafeFolderName(invalidFolderName));
                }
            }

            [Fact]
            public void ShouldRemoveAnySpaces()
            {
                Assert.Equal("Alotofspaces", new FileSystem().GetSafeFolderName("A lot of spaces"));
            }
        }
    }
}