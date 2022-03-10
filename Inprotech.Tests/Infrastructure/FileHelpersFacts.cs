using Inprotech.Infrastructure;
using Xunit;

namespace Inprotech.Tests.Infrastructure
{
    public class FileHelpersFacts
    {
        public class FilePathValidMethod
        {
            readonly IFileHelpers _helper;

            public FilePathValidMethod()
            {
                _helper = new FileHelpers();
            }

            [Theory]
            [InlineData(@"c:")]
            [InlineData(@"\\server\")]
            [InlineData(@"\\server\directory")]
            [InlineData(@"\\server\directory.new")]
            [InlineData(@"C:\directory.new")]
            [InlineData(@"C:\dire_ct@or(y.n)ew")]
            public void ShouldReturnTrueIfPathIsValid(string path)
            {
                var r = _helper.FilePathValid(path);
                Assert.True(r);
            }

            [Theory]
            [InlineData(@"a")]
            [InlineData(@"\\server\..\directory")]
            [InlineData(@"c.")]
            public void ShouldReturnFalseIfTheUrlIsInvalid(string path)
            {
                var r = _helper.FilePathValid(path);
                Assert.False(r);
            }
        }
    }
}