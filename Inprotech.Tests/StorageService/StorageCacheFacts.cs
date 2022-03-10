using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.DependencyInjection;
using Inprotech.StorageService.Storage;
using Inprotech.Web.Configuration.Attachments;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.StorageService
{
    public class StorageCacheFacts
    {
        public class StorageCacheFixture : IFixture<StorageCache>
        {
            public StorageCacheFixture(Dictionary<string, IEnumerable<string>> filePaths = null)
            {
                FileHelpers = Substitute.For<IFileHelpers>();
                if (filePaths != null)
                {
                    foreach (var key in filePaths.Keys) FileHelpers.EnumerateDirectories(key).Returns(filePaths[key]);
                }

                RecursivelySearchForPathInCache = Substitute.For<IRecursivelySearchForPathInCache>();
                AttachmentSettings = Substitute.For<IAttachmentSettings>();
                LifetimeScope = Substitute.For<ILifetimeScope>();

                LifetimeScope.BeginLifetimeScope().Returns(LifetimeScope);
                LifetimeScope.Resolve<IAttachmentSettings>().Returns(AttachmentSettings);

                Subject = new StorageCache(FileHelpers, RecursivelySearchForPathInCache, LifetimeScope, Substitute.For<IBackgroundProcessLogger<StorageCache>>());
            }

            public IFileHelpers FileHelpers { get; }
            public IRecursivelySearchForPathInCache RecursivelySearchForPathInCache { get; }
            public IAttachmentSettings AttachmentSettings { get; }
            public ILifetimeScope LifetimeScope { get; }
            public StorageCache Subject { get; }
        }

        public class FetchFilePathsMethod : IDisposable
        {
            StorageCacheFixture _fixture;
            public FetchFilePathsMethod()
            {
                var prefix = Guid.NewGuid().ToString();
                _directory = Directory.CreateDirectory(prefix + "abc").FullName;
            }

            readonly string _directory;

            public void Dispose()
            {
                _fixture.Subject.RemoveExistingWatchers();
                Directory.Delete(_directory, true);
            }

            [Fact]
            public async Task ShouldReturnEmptyListAndNotContinueIfNoTopLevelFolderFoundMatchingPath()
            {
                _fixture = new StorageCacheFixture();
                await _fixture.Subject.RebuildEntireCache();
                _fixture.RecursivelySearchForPathInCache.RecursivelySearchInCache(Arg.Any<string>(), Arg.Any<IEnumerable<FilePathModel>>()).Returns(Task.FromResult<FilePathModel>(null));

                var files = await _fixture.Subject.FetchFilePaths(Fixture.String());

                _fixture.FileHelpers.DidNotReceive().GetFileInfos(Arg.Any<string>());
                Assert.Equal(0, files.Count());
            }

            [Fact]
            public async Task ShouldReturnEmptyListIfNoMatchingStorageLocationsInSettings()
            {
                _fixture = new StorageCacheFixture();
                _fixture.AttachmentSettings.Resolve().Returns(Task.FromResult(new AttachmentSetting
                {
                    StorageLocations = new AttachmentSetting.StorageLocation[0]
                }));
                await _fixture.Subject.RebuildEntireCache();
                _fixture.RecursivelySearchForPathInCache.RecursivelySearchInCache(Arg.Any<string>(), Arg.Any<IEnumerable<FilePathModel>>()).Returns(new FilePathModel());

                var files = await _fixture.Subject.FetchFilePaths(Fixture.String());
                _fixture.FileHelpers.DidNotReceive().GetFileInfos(Arg.Any<string>());
                Assert.Equal(0, files.Count());
            }

            [Fact]
            public async Task ShouldRetrieveFilesForPathIfLocationFound()
            {
                var path = Fixture.String();
                _fixture = new StorageCacheFixture();
                _fixture.AttachmentSettings.Resolve().Returns(Task.FromResult(new AttachmentSetting
                {
                    StorageLocations = new[]
                    {
                        new AttachmentSetting.StorageLocation()
                        {
                            Path = path
                        }
                    }
                }));
                await _fixture.Subject.RebuildEntireCache();
                _fixture.RecursivelySearchForPathInCache.RecursivelySearchInCache(Arg.Any<string>(), Arg.Any<IEnumerable<FilePathModel>>()).Returns(new FilePathModel() { Path = path });

                var files = await _fixture.Subject.FetchFilePaths(path);

                _fixture.FileHelpers.Received(1).GetFileInfos(path);
                Assert.Equal(0, files.Count());
            }

            [Fact]
            public async Task ShouldRetrieveFilesWithValidExtensions()
            {
                var path = Fixture.String();
                Func<string, FileInfo> CreateFile = (string fileName) =>
                {
                    var fullFileName = Path.Combine(_directory, fileName);
                    if (!File.Exists(fullFileName))
                        File.WriteAllText(fullFileName, "test");
                    return new FileInfo(fullFileName);
                };
                _fixture = new StorageCacheFixture();
                _fixture.AttachmentSettings.Resolve().Returns(Task.FromResult(new AttachmentSetting
                {
                    StorageLocations = new[]
                    {
                        new AttachmentSetting.StorageLocation()
                        {
                            Path = path,
                            AllowedFileExtensions = "txt,doc,pdf"
                        }
                    }
                }));
                await _fixture.Subject.RebuildEntireCache();
                _fixture.RecursivelySearchForPathInCache.RecursivelySearchInCache(Arg.Any<string>(), Arg.Any<IEnumerable<FilePathModel>>()).Returns(new FilePathModel() { Path = path });
                _fixture.FileHelpers.GetFileInfos(path).Returns(new[]
                {
                    CreateFile("test1.txt"),
                    CreateFile("test2.pdf"),
                    CreateFile("test3.doc"),
                    CreateFile("test4.fail")
                });
                var files = (await _fixture.Subject.FetchFilePaths(path)).ToList();

                _fixture.FileHelpers.Received(1).GetFileInfos(path);
                Assert.Equal(3, files.Count());
                Assert.Equal("test1.txt", files[0].PathShortName);
                Assert.Equal("test2.pdf", files[1].PathShortName);
                Assert.Equal("test3.doc", files[2].PathShortName);
            }

            [Fact]
            public async Task ShouldRetreiveFilesForMappedPaths()
            {
                var relativePath = Fixture.String();
                var driveLetter = Fixture.String();
                var searchedPath = driveLetter + ":\\" + relativePath;
                var driveReplacementUncPath = Fixture.String();
                _fixture = new StorageCacheFixture();
                _fixture.AttachmentSettings.Resolve().Returns(Task.FromResult(new AttachmentSetting
                {
                    StorageLocations = new[]
                    {
                        new AttachmentSetting.StorageLocation()
                        {
                            Path = searchedPath
                        },
                        new AttachmentSetting.StorageLocation()
                        {
                        Path = Fixture.String()
                        }
                    },
                    NetworkDrives = new[]
                    {
                        new AttachmentSetting.NetworkDrive()
                        {
                            DriveLetter = driveLetter,
                            UncPath = driveReplacementUncPath
                        },
                        new AttachmentSetting.NetworkDrive()
                        {
                        DriveLetter = Fixture.String(),
                        UncPath = Fixture.String()
                        }
                    }
                }));
                await _fixture.Subject.RebuildEntireCache();
                _fixture.RecursivelySearchForPathInCache.RecursivelySearchInCache(Arg.Any<string>(), Arg.Any<IEnumerable<FilePathModel>>()).Returns(new FilePathModel() { Path = searchedPath });

                var files = await _fixture.Subject.FetchFilePaths(searchedPath);

                _fixture.FileHelpers.Received(1).GetFileInfos(Path.Combine(driveReplacementUncPath, relativePath));
                Assert.Equal(0, files.Count());
            }
        }

        public class FetchFoldersMethod
        {
            readonly string _directory = "testdirectory";
            StorageCacheFixture _fixture;

            [Fact]
            public async Task ShouldReturnCachedAndSubFolders()
            {
                var settings = new AttachmentSetting
                {
                    StorageLocations = new[]
                    {
                        new AttachmentSetting.StorageLocation {Path = _directory, Name = "test"}
                    }
                };
                var filePaths = new Dictionary<string, IEnumerable<string>>
                {
                    {
                        _directory, new[]
                        {
                            Path.Combine(_directory, "C"),
                            Path.Combine(_directory, "A"),
                            Path.Combine(_directory, "B")
                        }
                    },
                    {
                        Path.Combine(_directory, "C"),
                        new[]
                        {
                            Path.Combine(_directory, "C", "C1"),
                            Path.Combine(_directory, "C", "C2"),
                            Path.Combine(_directory, "C", "C3")
                        }
                    },
                    {
                        Path.Combine(_directory, "A"),
                        new[]
                        {
                            Path.Combine(_directory, "A", "A1"),
                            Path.Combine(_directory, "A", "A2")
                        }
                    }
                };
                _fixture = new StorageCacheFixture(filePaths);
                _fixture.AttachmentSettings.Resolve().Returns(Task.FromResult(settings));
                await _fixture.Subject.RebuildEntireCache();
                var mapped = false;
                while (_fixture.Subject.FoldersBeingMapped != 0)
                {
                    mapped = false;
                }

                mapped = true;
                var folders = (await _fixture.Subject.FetchFolders()).ToList();

                Assert.Equal(1, folders.Count());
                Assert.Equal("A", folders.First().SubFolders.ToList()[0].PathShortName);
                Assert.Equal(2, folders.First().SubFolders.ToList()[0].SubFolders.Count());
                Assert.Equal("A1", folders.First().SubFolders.ToList()[0].SubFolders.ToList()[0].PathShortName);
                Assert.Equal("A2", folders.First().SubFolders.ToList()[0].SubFolders.ToList()[1].PathShortName);
                Assert.Equal(Path.Combine(_directory, "A", "A1") + Path.DirectorySeparatorChar, folders.First().SubFolders.ToList()[0].SubFolders.ToList()[0].Path);
                Assert.Equal(Path.Combine(_directory, "A", "A2") + Path.DirectorySeparatorChar, folders.First().SubFolders.ToList()[0].SubFolders.ToList()[1].Path);
                Assert.Equal(0, folders.First().SubFolders.ToList()[0].SubFolders.ToList()[0].SubFolders.Count());
                Assert.Equal(0, folders.First().SubFolders.ToList()[0].SubFolders.ToList()[1].SubFolders.Count());

                Assert.Equal("B", folders.First().SubFolders.ToList()[1].PathShortName);
                Assert.Equal(0, folders.First().SubFolders.ToList()[1].SubFolders.Count());

                Assert.Equal("C", folders.First().SubFolders.ToList()[2].PathShortName);
                Assert.Equal(3, folders.First().SubFolders.ToList()[2].SubFolders.Count());
                Assert.Equal("C1", folders.First().SubFolders.ToList()[2].SubFolders.ToList()[0].PathShortName);
                Assert.Equal("C2", folders.First().SubFolders.ToList()[2].SubFolders.ToList()[1].PathShortName);
                Assert.Equal("C3", folders.First().SubFolders.ToList()[2].SubFolders.ToList()[2].PathShortName);
                Assert.Equal(0, folders.First().SubFolders.ToList()[2].SubFolders.ToList()[0].SubFolders.Count());
                Assert.Equal(0, folders.First().SubFolders.ToList()[2].SubFolders.ToList()[1].SubFolders.Count());
                Assert.Equal(0, folders.First().SubFolders.ToList()[2].SubFolders.ToList()[2].SubFolders.Count());
                Assert.Equal(Path.Combine(_directory, "C", "C1") + Path.DirectorySeparatorChar, folders.First().SubFolders.ToList()[2].SubFolders.ToList()[0].Path);
                Assert.Equal(Path.Combine(_directory, "C", "C2") + Path.DirectorySeparatorChar, folders.First().SubFolders.ToList()[2].SubFolders.ToList()[1].Path);
                Assert.Equal(Path.Combine(_directory, "C", "C3") + Path.DirectorySeparatorChar, folders.First().SubFolders.ToList()[2].SubFolders.ToList()[2].Path);

            }

            [Fact]
            public async Task ShouldReturnCachedFoldersOrderedByShortName()
            {
                var settings = new AttachmentSetting
                {
                    StorageLocations = new[]
                    {
                        new AttachmentSetting.StorageLocation {Path = _directory, Name = "test"}
                    }
                };
                var filePaths = new Dictionary<string, IEnumerable<string>>
                {
                    {
                        _directory, new[]
                        {
                            Path.Combine(_directory, "C"),
                            Path.Combine(_directory, "A"),
                            Path.Combine(_directory, "B")
                        }
                    }
                };

                _fixture = new StorageCacheFixture(filePaths);
                _fixture.AttachmentSettings.Resolve().Returns(settings);
                await _fixture.Subject.RebuildEntireCache();
                var mapped = false;
                while (_fixture.Subject.FoldersBeingMapped != 0)
                {
                    mapped = false;
                }

                mapped = true;

                var folders = (await _fixture.Subject.FetchFolders()).ToList();

                Assert.Equal(1, folders.Count());
                Assert.Equal("A", folders.First().SubFolders.ToList()[0].PathShortName);
                Assert.Equal("B", folders.First().SubFolders.ToList()[1].PathShortName);
                Assert.Equal("C", folders.First().SubFolders.ToList()[2].PathShortName);
            }
        }
    }
}