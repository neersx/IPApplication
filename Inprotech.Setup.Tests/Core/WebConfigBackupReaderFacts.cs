using System.IO;
using System.Xml.Linq;
using Inprotech.Setup.Core;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class WebConfigBackupReaderFacts
    {
        const string WebConfigRelease8AndBeyond = ".\\WebConfigs";

        readonly IAuthenticationMode _authMode = Substitute.For<IAuthenticationMode>();

        IWebConfigBackupReader CreateSubject(string mode)
        {
            _authMode.ResolveFromBackupConfig(Arg.Any<XElement>()).Returns(mode);

            return new WebConfigBackupReader(_authMode, new FileSystem());
        }

        [Fact]
        public void ReturnsData()
        {
            const string authmodes = "Some auth modes";
            var reader = CreateSubject(authmodes);

            var webconfigBackup = reader.Read(Path.GetFullPath(WebConfigRelease8AndBeyond));
            _authMode.Received(1).ResolveFromBackupConfig(Arg.Any<XElement>());

            Assert.True(webconfigBackup.Exists);
            Assert.Equal(authmodes, webconfigBackup.AuthenticationMode);
        }

        [Fact]
        public void ReturnsNullIfFileNotFound()
        {
            var reader = CreateSubject(null);
            var webconfigBackup = reader.Read("somepath");

            Assert.False(webconfigBackup.Exists);
        }
    }
}