using System.IO;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.IntegrationServer.PtoAccess.CleanUp;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.CleanUp
{
    public class LegacyDirectoriesFacts
    {
        public LegacyDirectoriesFacts()
        {
            var storageLocation = Substitute.For<IStorageLocation>();
            var fileHelpers = Substitute.For<IFileHelpers>();
            var fileSystem = Substitute.For<IFileSystem>();
            _legacyDirectories = new LegacyDirectories(storageLocation, fileHelpers, fileSystem);

            storageLocation.Resolve().Returns("c:\\root");
            fileHelpers.EnumerateDirectories("c:\\root").Returns(new[] {"c:\\root\\UsptoIntegration"});
            fileHelpers.EnumerateDirectories("c:\\root\\UsptoIntegration", "*", SearchOption.AllDirectories).Returns(new[] {"c:\\root\\UsptoIntegration\\63ee7f2b-3eb1-43f9-97e1-c3bfe029fb85"});
            fileHelpers.GetFiles("c:\\root\\UsptoIntegration", "*",
                                 SearchOption.AllDirectories).Returns(new[] {"c:\\root\\UsptoIntegration\\63ee7f2b-3eb1-43f9-97e1-c3bfe029fb85\\cpa-xml.xml"});
            fileHelpers.GetFileInfo("c:\\root\\UsptoIntegration\\63ee7f2b-3eb1-43f9-97e1-c3bfe029fb85\\cpa-xml.xml").Returns(new FileInfoWrapper {LastWriteTime = Fixture.Today()});
            fileSystem.RelativeStorageLocationPath("c:\\root\\UsptoIntegration\\63ee7f2b-3eb1-43f9-97e1-c3bfe029fb85").Returns("\\UsptoIntegration\\63ee7f2b-3eb1-43f9-97e1-c3bfe029fb85");
        }

        readonly LegacyDirectories _legacyDirectories;

        [Fact]
        public void ShouldNotReturnNewFilesAfterScheduleExecutionIntroduced()
        {
            var dirs = _legacyDirectories.Enumerate(Fixture.PastDate());

            Assert.False(dirs.Any());
        }

        [Fact]
        public void ShouldReturnLegacyFiles()
        {
            var dirs = _legacyDirectories.Enumerate(Fixture.FutureDate());

            Assert.Equal("\\UsptoIntegration\\63ee7f2b-3eb1-43f9-97e1-c3bfe029fb85", dirs.Single());
        }
    }
}