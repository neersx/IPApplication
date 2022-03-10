using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Schedules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Artifacts
{
    public class DataDownloadLocationResolverFacts
    {
        public class ResolveMethod
        {
            [Theory]
            [InlineData(@"PtoIntegration\UsptoTsdr\b\0e6f2264-9698-45e9-b94a-37f390c622b6\1", "PtoIntegration", DataSourceType.UsptoTsdr, "b", "0e6f2264-9698-45e9-b94a-37f390c622b6", 1, null)]
            [InlineData(@"PtoIntegration\UsptoTsdr\b\0e6f2264-9698-45e9-b94a-37f390c622b6\1\d.txt", "PtoIntegration", DataSourceType.UsptoTsdr, "b", "0e6f2264-9698-45e9-b94a-37f390c622b6", 1, "d.txt")]
            [InlineData(@"PtoIntegration\UsptoTsdr\b\0e6f2264-9698-45e9-b94a-37f390c622b6", "PtoIntegration", DataSourceType.UsptoTsdr, "b", "0e6f2264-9698-45e9-b94a-37f390c622b6", null, null)]
            [InlineData(@"PtoIntegration\UsptoTsdr\b\0e6f2264-9698-45e9-b94a-37f390c622b6\d.txt", "PtoIntegration", DataSourceType.UsptoTsdr, "b", "0e6f2264-9698-45e9-b94a-37f390c622b6", null, "d.txt")]
            public void ResolvesLocationCorrectly(string expectedLocation, string root, DataSourceType dataSource, string scheduleName,
                                                  string currentSessionIdentifier, int? canonicalCaseIdentifier, string fileName)
            {
                var dataDownload = new DataDownload
                {
                    DataSourceType = dataSource,
                    Name = scheduleName,
                    Id = new Guid(currentSessionIdentifier)
                };

                var sessionRoot = Path.Combine(new List<string>
                {
                    root,
                    dataSource.ToString(),
                    scheduleName,
                    currentSessionIdentifier
                }.ToArray());

                if (canonicalCaseIdentifier.HasValue)
                {
                    dataDownload.Case = new EligibleCase
                    {
                        CaseKey = canonicalCaseIdentifier.Value
                    };
                }

                var fixture = new DataDownloadLocationResolverFixture();

                fixture.SessionRootResolver.Resolve(dataDownload.Id).Returns(sessionRoot);

                Assert.Equal(expectedLocation, fixture.Subject.Resolve(dataDownload, fileName));
            }

            [Theory]
            [InlineData(@"rootfolder\1\1000\fileName", 1, 1000, "fileName")]
            [InlineData(@"rootfolder\1\1000", 1, 1000, "   ")]
            [InlineData(@"rootfolder\1\fileName", 1, null, "fileName")]
            [InlineData(@"rootfolder\1000", null, 1000, "   ")]
            [InlineData(@"rootfolder\fileName", null, null, "fileName")]
            public void ResolveConsidersChunk(string expectedPath, int? chunk, int? caseIndentifier, string fileName)
            {
                var fixture = new DataDownloadLocationResolverFixture();
                fixture.SessionRootResolver.Resolve(Arg.Any<Guid>()).Returns("rootfolder");

                var dataDownload = new DataDownload
                {
                    Id = Guid.NewGuid(),
                    Case = caseIndentifier.HasValue
                        ? new EligibleCase
                        {
                            CaseKey = caseIndentifier.Value
                        }
                        : null,
                    Chunk = chunk
                };

                var resultedPath = fixture.Subject.Resolve(dataDownload, fileName);

                fixture.SessionRootResolver.Received(1).Resolve(dataDownload.Id);

                Assert.Equal(expectedPath, resultedPath);
            }
        }

        public class ResolveRoot
        {
            [Theory]
            [InlineData(@"PtoIntegration\UsptoTsdr\b\0e6f2264-9698-45e9-b94a-37f390c622b6", "PtoIntegration", DataSourceType.UsptoTsdr, "b", "0e6f2264-9698-45e9-b94a-37f390c622b6", null)]
            [InlineData(@"PtoIntegration\UsptoTsdr\b\0e6f2264-9698-45e9-b94a-37f390c622b6\d.txt", "PtoIntegration", DataSourceType.UsptoTsdr, "b", "0e6f2264-9698-45e9-b94a-37f390c622b6", "d.txt")]
            public void ResolvesLocationCorrectly(string expectedLocation, string root, DataSourceType dataSource, string scheduleName,
                                                  string currentSessionIdentifier, string fileName)
            {
                var dataDownload = new DataDownload
                {
                    DataSourceType = dataSource,
                    Name = scheduleName,
                    Id = new Guid(currentSessionIdentifier)
                };

                var sessionRoot = Path.Combine(new List<string>
                {
                    root,
                    dataSource.ToString(),
                    scheduleName,
                    currentSessionIdentifier
                }.ToArray());

                dataDownload.Case = new EligibleCase
                {
                    CaseKey = Fixture.Integer()
                };

                var fixture = new DataDownloadLocationResolverFixture();

                fixture.SessionRootResolver.Resolve(dataDownload.Id).Returns(sessionRoot);

                Assert.Equal(expectedLocation, fixture.Subject.ResolveRoot(dataDownload, fileName));
            }
        }

        public class ResolveForErrorLog
        {
            [Theory]
            [InlineData(@"rootfolder\1\Logs\1000\fileName", 1, 1000, "fileName")]
            [InlineData(@"rootfolder\1\Logs\1000", 1, 1000, "   ")]
            [InlineData(@"rootfolder\1\Logs\fileName", 1, null, "fileName")]
            [InlineData(@"rootfolder\Logs\1000", null, 1000, "   ")]
            [InlineData(@"rootfolder\Logs\fileName", null, null, "fileName")]
            public void ResolveConsidersChunk(string expectedPath, int? chunk, int? caseIndentifier, string fileName)
            {
                var fixture = new DataDownloadLocationResolverFixture();
                fixture.SessionRootResolver.Resolve(Arg.Any<Guid>()).Returns("rootfolder");

                var dataDownload = new DataDownload
                {
                    Id = Guid.NewGuid(),
                    Case = caseIndentifier.HasValue
                        ? new EligibleCase
                        {
                            CaseKey = caseIndentifier.Value
                        }
                        : null,
                    Chunk = chunk
                };

                var resultedPath = fixture.Subject.ResolveForErrorLog(dataDownload, fileName);

                fixture.SessionRootResolver.Received(1).Resolve(dataDownload.Id);

                Assert.Equal(expectedPath, resultedPath);
            }
        }
    }

    internal class DataDownloadLocationResolverFixture : IFixture<DataDownloadLocationResolver>
    {
        public IResolveScheduleExecutionRootFolder SessionRootResolver = Substitute.For<IResolveScheduleExecutionRootFolder>();

        public DataDownloadLocationResolver Subject => new DataDownloadLocationResolver(SessionRootResolver);
    }
}