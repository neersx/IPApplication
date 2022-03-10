using Inprotech.Setup.Core;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class HelpersFacts
    {
        [Fact]
        public void CanFindWebApp()
        {
            var webApp = new WebAppInfo("a", null, new SetupSettings {IisSite = "a", IisPath = "b"}, null);
            var found = Helpers.FindWebApp(new[] {webApp}, "A", "B");
            Assert.Equal(webApp, found);
        }

        [Fact]
        public void GetInstanceName()
        {
            Assert.Equal("instance-1", Helpers.GetInstanceName("c:/instance-1"));
            Assert.Equal("instance-1", Helpers.GetInstanceName("c:/instance-1/"));
        }

        [Fact]
        public void NormalizePath()
        {
            Assert.Equal(@"c:\a", Helpers.NormalizePath("c:/a/"));
        }

        [Fact]
        public void PathsAreEqual()
        {
            Assert.True(Helpers.ArePathsEqual("path1", "path1"));
            Assert.True(Helpers.ArePathsEqual("c:\\path1", "c:/path1"));
        }

        [Fact]
        public void PathsAreNotEqual()
        {
            Assert.False(Helpers.ArePathsEqual("path1", "path2"));
            Assert.False(Helpers.ArePathsEqual("c:\\path1", "c:\\path2"));
        }
    }
}