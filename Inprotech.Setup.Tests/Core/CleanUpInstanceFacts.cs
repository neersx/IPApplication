using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Actions;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Core
{
    public class CleanUpInstanceFacts
    {
        public class RunAsyncMethod
        {
            readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
            readonly IInprotechServerPersistingConfigManager _manager = Substitute.For<IInprotechServerPersistingConfigManager>();
            readonly IEventStream _eventStream = Substitute.For<IEventStream>();

            readonly SetupContext _context = new SetupContext
            {
                {"InprotechConnectionString", "abc"},
                {"InstanceDirectory", @"c:\somelocation\instances\instance-1"},
                {"InstanceName", "instance-1"}
            };

            CleanUpInstance CreateSubject(InstanceDetails instanceDetails = null)
            {
                var i = instanceDetails ?? new InstanceDetails();
                _manager.GetPersistedInstanceDetails(Arg.Any<string>())
                        .Returns(i);

                return new CleanUpInstance(_fileSystem, _manager);
            }

            [Fact]
            public async Task DeletesInstanceFiles()
            {
                await CreateSubject().RunAsync(_context, _eventStream);

                _fileSystem.Received(1).DeleteAllExcept(_context.InstancePath, Constants.SettingsFileName);

                _fileSystem.Received(1).DeleteDirectory(_context.InstancePath);
            }

            [Fact]
            public async Task RemovesInstanceDetailsFromDb()
            {
                var inprotechServerToRemove = new InstanceServiceStatus
                {
                    Name = "instance-1"
                };

                var integrationServerToRemove = new InstanceServiceStatus
                {
                    Name = "instance-1"
                };

                var details = new InstanceDetails
                {
                    InprotechServer = new List<InstanceServiceStatus>(new[] {inprotechServerToRemove}),
                    IntegrationServer = new List<InstanceServiceStatus>(new[] {integrationServerToRemove})
                };

                await CreateSubject(details).RunAsync(_context, _eventStream);

                _manager.Received(1)
                        .SetPersistedInstanceDetails(Arg.Any<string>(),
                                                     Arg.Is<InstanceDetails>(x => !x.InprotechServer.Any() && !x.IntegrationServer.Any()))
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task RetriesFileDeleteThrice()
            {
                var i = 0;

                _fileSystem.WhenForAnyArgs(x => x.DeleteDirectory(null))
                           .Do(x =>
                           {
                               if (i++ < 2)
                               {
                                   throw new Exception("bummer");
                               }
                           });

                await CreateSubject().RunAsync(_context, _eventStream);

                _fileSystem.Received(3).DeleteAllExcept(_context.InstancePath, Constants.SettingsFileName);

                _fileSystem.Received(3).DeleteDirectory(_context.InstancePath);
            }
        }

        public class RunMethod
        {
            readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
            readonly IInprotechServerPersistingConfigManager _manager = Substitute.For<IInprotechServerPersistingConfigManager>();
            readonly IEventStream _eventStream = Substitute.For<IEventStream>();

            readonly SetupContext _context = new SetupContext
            {
                {"InprotechConnectionString", "abc"},
                {"InstanceDirectory", @"c:\somelocation\instances\instance-1"},
                {"InstanceName", "instance-1"}
            };

            CleanUpInstance CreateSubject(InstanceDetails instanceDetails = null)
            {
                var i = instanceDetails ?? new InstanceDetails();
                _manager.GetPersistedInstanceDetails(Arg.Any<string>())
                        .Returns(i);

                return new CleanUpInstance(_fileSystem, _manager);
            }

            [Fact]
            public void DeletesInstanceFiles()
            {
                CreateSubject().Run(_context, _eventStream);

                _fileSystem.Received(1).DeleteAllExcept(_context.InstancePath, Constants.SettingsFileName);

                _fileSystem.Received(1).DeleteDirectory(_context.InstancePath);
            }

            [Fact]
            public void RemovesInstanceDetailsFromDb()
            {
                var inprotechServerToRemove = new InstanceServiceStatus
                {
                    Name = "instance-1"
                };

                var integrationServerToRemove = new InstanceServiceStatus
                {
                    Name = "instance-1"
                };

                var details = new InstanceDetails
                {
                    InprotechServer = new List<InstanceServiceStatus>(new[] {inprotechServerToRemove}),
                    IntegrationServer = new List<InstanceServiceStatus>(new[] {integrationServerToRemove})
                };

                CreateSubject(details).Run(_context, _eventStream);

                _manager.Received(1)
                        .SetPersistedInstanceDetails(Arg.Any<string>(),
                                                     Arg.Is<InstanceDetails>(x => !x.InprotechServer.Any() && !x.IntegrationServer.Any()))
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public void RetriesFileDeleteThrice()
            {
                var i = 0;

                _fileSystem.WhenForAnyArgs(x => x.DeleteDirectory(null))
                           .Do(x =>
                           {
                               if (i++ < 2)
                               {
                                   throw new Exception("bummer");
                               }
                           });

                CreateSubject().Run(_context, _eventStream);

                _fileSystem.Received(3).DeleteAllExcept(_context.InstancePath, Constants.SettingsFileName);

                _fileSystem.Received(3).DeleteDirectory(_context.InstancePath);
            }
        }
    }
}