using System;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration.Schedules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class ArtifactsServiceFact
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void ExtractIntoDirectory()
            {
                var f = new ArtifactsServiceFixture();
                var data = new byte[1];
                var path = @"\\storage\folder1";
                var name = Guid.Empty + ".zip";
                var zipFullPath = $"{path}\\{name}";

                f.CompressionHelper.CreateZipFile(data, name).Returns(zipFullPath);
                f.FileSystem.AbsolutePath(path).Returns(path);

                f.Subject.ExtractIntoDirectory(data, path);
                f.CompressionHelper.Received(1).CreateZipFile(data, name);
                f.CompressionHelper.Received(1).ExtractToDirectory(zipFullPath, path);
                f.FileSystem.Received(1).DeleteFile(name);
            }
        }

        public class ArtifactsServiceFixture : IFixture<IArtifactsService>
        {
            public ArtifactsServiceFixture()
            {
                FileSystem = Substitute.For<IFileSystem>();
                FileHelpers = Substitute.For<IFileHelpers>();
                CompressionHelper = Substitute.For<ICompressionHelper>();

                Subject = new ArtifactsService(FileSystem, FileHelpers, CompressionHelper, () => Guid.Empty);
            }

            public IFileSystem FileSystem { get; }

            public IFileHelpers FileHelpers { get; }

            public ICompressionHelper CompressionHelper { get; }

            public IArtifactsService Subject { get; }
        }
    }
}